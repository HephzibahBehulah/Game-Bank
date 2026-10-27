import asyncio, base64, hashlib, hmac, json, os, re, secrets, time, uuid
from datetime import datetime, timezone, timedelta
from pathlib import Path
from typing import Optional

from fastapi import Depends, FastAPI, HTTPException, Header
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, EmailStr, Field
from sqlalchemy import Boolean, DateTime, Float, ForeignKey, Integer, String, Text, create_engine, select, func, inspect, text
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column, sessionmaker, Session

ROOT=Path(__file__).resolve().parent
DB_URL=os.getenv("DATABASE_URL",f"sqlite:///{ROOT/'gamebank.db'}")
connect_args={"check_same_thread":False} if DB_URL.startswith("sqlite") else {}
engine=create_engine(DB_URL,connect_args=connect_args,pool_pre_ping=True)
SessionLocal=sessionmaker(bind=engine,expire_on_commit=False)
class Base(DeclarativeBase): pass
class User(Base):
    __tablename__="users"
    id:Mapped[int]=mapped_column(Integer,primary_key=True); email:Mapped[str]=mapped_column(String(254),unique=True,index=True); display_name:Mapped[str]=mapped_column(String(80)); password_hash:Mapped[str]=mapped_column(String(256)); role:Mapped[str]=mapped_column(String(16),default="player"); created_at:Mapped[datetime]=mapped_column(DateTime,default=lambda:datetime.now(timezone.utc))
class Model(Base):
    __tablename__="models"
    id:Mapped[int]=mapped_column(Integer,primary_key=True); key:Mapped[str]=mapped_column(String(50),unique=True); label:Mapped[str]=mapped_column(String(80)); provider:Mapped[str]=mapped_column(String(30)); enabled:Mapped[bool]=mapped_column(Boolean,default=True)
class Match(Base):
    __tablename__="matches"
    id:Mapped[str]=mapped_column(String(36),primary_key=True); user_id:Mapped[int]=mapped_column(ForeignKey("users.id")); prompt:Mapped[str]=mapped_column(Text); task_type:Mapped[str]=mapped_column(String(20)); mode:Mapped[str]=mapped_column(String(20)); created_at:Mapped[datetime]=mapped_column(DateTime,default=lambda:datetime.now(timezone.utc))
class Response(Base):
    __tablename__="responses"
    id:Mapped[int]=mapped_column(Integer,primary_key=True); match_id:Mapped[str]=mapped_column(ForeignKey("matches.id"),index=True); model_key:Mapped[str]=mapped_column(String(50)); body:Mapped[str]=mapped_column(Text); latency_ms:Mapped[float]=mapped_column(Float); state:Mapped[str]=mapped_column(String(20)); error:Mapped[Optional[str]]=mapped_column(Text,nullable=True)
class Score(Base):
    __tablename__="scores"
    id:Mapped[int]=mapped_column(Integer,primary_key=True); match_id:Mapped[str]=mapped_column(ForeignKey("matches.id"),index=True); model_key:Mapped[str]=mapped_column(String(50)); accuracy:Mapped[Optional[float]]=mapped_column(Float,nullable=True); final_score:Mapped[Optional[float]]=mapped_column(Float,nullable=True); source:Mapped[str]=mapped_column(String(24)); rating:Mapped[Optional[int]]=mapped_column(Integer,nullable=True)
class Audit(Base):
    __tablename__="audit_log"
    id:Mapped[int]=mapped_column(Integer,primary_key=True); actor_id:Mapped[Optional[int]]=mapped_column(Integer,nullable=True); action:Mapped[str]=mapped_column(String(60)); subject:Mapped[str]=mapped_column(String(120)); created_at:Mapped[datetime]=mapped_column(DateTime,default=lambda:datetime.now(timezone.utc))
class IQRun(Base):
    __tablename__="iq_runs"
    id:Mapped[str]=mapped_column(String(36),primary_key=True); user_id:Mapped[int]=mapped_column(ForeignKey("users.id")); difficulty:Mapped[int]=mapped_column(Integer,default=2); question_no:Mapped[int]=mapped_column(Integer,default=0); score:Mapped[int]=mapped_column(Integer,default=0); categories:Mapped[str]=mapped_column(Text,default="{}"); finished:Mapped[bool]=mapped_column(Boolean,default=False); seed:Mapped[int]=mapped_column(Integer)
Base.metadata.create_all(engine)
with engine.begin() as conn:
    if "rating" not in {column["name"] for column in inspect(conn).get_columns("scores")}:
        conn.execute(text("ALTER TABLE scores ADD COLUMN rating INTEGER"))
with SessionLocal() as db:
    for key,label,provider in [("openai","OpenAI","openai"),("anthropic","Anthropic","anthropic"),("gemini","Google Gemini","gemini"),("deepseek","DeepSeek","deepseek"),("grok","Grok","xai"),("ollama","Ollama","ollama")]:
        if not db.scalar(select(Model).where(Model.key==key)): db.add(Model(key=key,label=label,provider=provider,enabled=True))
    db.commit()

if os.getenv("APP_ENV")=="production":
    configured_secret=os.getenv("JWT_SECRET","")
    if len(configured_secret)<32 or "replace-" in configured_secret.lower() or configured_secret=="local-development-secret-change-this":raise RuntimeError("Production requires a unique JWT_SECRET of at least 32 characters")
app=FastAPI(title="Hephzibah Behulah Game Platform API",version="1.0.0")
app.add_middleware(CORSMiddleware,allow_origins=os.getenv("CORS_ORIGINS","http://localhost:3000").split(","),allow_credentials=True,allow_methods=["GET","POST"],allow_headers=["Authorization","Content-Type"])
def get_db():
    with SessionLocal() as db: yield db

def b64(x:bytes)->str:return base64.urlsafe_b64encode(x).decode().rstrip("=")
def pw_hash(password:str)->str:
    salt=secrets.token_bytes(16); rounds=310000; digest=hashlib.pbkdf2_hmac("sha256",password.encode(),salt,rounds)
    return f"pbkdf2_sha256${rounds}${b64(salt)}${b64(digest)}"
def pw_ok(password:str,stored:str)->bool:
    try: _,rounds,salt,digest=stored.split("$"); candidate=hashlib.pbkdf2_hmac("sha256",password.encode(),base64.urlsafe_b64decode(salt+"=="),int(rounds)); return hmac.compare_digest(b64(candidate),digest)
    except Exception:return False
def token_for(user:User)->str:
    secret=os.getenv("JWT_SECRET","local-development-secret-change-this")
    if os.getenv("APP_ENV")=="production" and secret=="local-development-secret-change-this": raise HTTPException(503,"JWT_SECRET must be configured")
    header=b64(b'{"alg":"HS256","typ":"JWT"}'); payload=b64(json.dumps({"sub":user.id,"role":user.role,"exp":int(time.time())+43200}).encode()); sig=b64(hmac.new(secret.encode(),f"{header}.{payload}".encode(),hashlib.sha256).digest()); return f"{header}.{payload}.{sig}"
def current_user(authorization:str=Header(default=""),db:Session=Depends(get_db))->User:
    if not authorization.startswith("Bearer "): raise HTTPException(401,"Sign in required")
    try:
        head,pay,sig=authorization[7:].split("."); secret=os.getenv("JWT_SECRET","local-development-secret-change-this"); expected=b64(hmac.new(secret.encode(),f"{head}.{pay}".encode(),hashlib.sha256).digest())
        if not hmac.compare_digest(sig,expected): raise ValueError()
        data=json.loads(base64.urlsafe_b64decode(pay+"=="));
        if data["exp"]<time.time(): raise ValueError()
        user=db.get(User,int(data["sub"]))
        if not user: raise ValueError()
        return user
    except Exception: raise HTTPException(401,"Session expired or invalid")
def admin_user(user:User=Depends(current_user))->User:
    if user.role!="admin": raise HTTPException(403,"Admin access required")
    return user

class RegisterIn(BaseModel): email:EmailStr; password:str=Field(min_length=12,max_length=128); display_name:str=Field(min_length=2,max_length=80)
class LoginIn(BaseModel): email:EmailStr; password:str
class BootstrapIn(RegisterIn): bootstrap_token:str
class ArenaIn(BaseModel): prompt:str=Field(min_length=12,max_length=8000); task_type:str="factual"; tests:list[dict]=Field(default_factory=list)
class RateIn(BaseModel): model_key:str; rating:int=Field(ge=1,le=5)

@app.get("/api/health")
def health():
    mode=os.getenv("AI_MODE","replay").lower()
    providers={key:mode=="live" and _provider_ready(key) for key in LABELS}
    return {"ok":True,"service":"game-platform-api","ai_mode":mode,"providers":providers}
@app.post("/api/auth/register")
def register(data:RegisterIn,db:Session=Depends(get_db)):
    email=str(data.email).lower()
    if db.scalar(select(User).where(User.email==email)): raise HTTPException(409,"Email already registered")
    user=User(email=email,display_name=data.display_name,password_hash=pw_hash(data.password),role="player"); db.add(user); db.commit(); db.refresh(user)
    db.add(Audit(actor_id=user.id,action="register",subject=email));db.commit()
    return {"token":token_for(user),"user":{"id":user.id,"email":user.email,"display_name":user.display_name,"role":user.role}}
@app.post("/api/auth/bootstrap-admin")
def bootstrap_admin(data:BootstrapIn,db:Session=Depends(get_db)):
    configured=os.getenv("ADMIN_EMAIL","").lower(); expected=os.getenv("ADMIN_BOOTSTRAP_TOKEN","")
    if not configured or not expected or str(data.email).lower()!=configured or not hmac.compare_digest(data.bootstrap_token,expected): raise HTTPException(403,"Admin bootstrap is not configured for this account")
    if db.scalar(select(User).where(User.role=="admin")): raise HTTPException(409,"An admin is already initialized")
    user=User(email=configured,display_name=data.display_name,password_hash=pw_hash(data.password),role="admin");db.add(user);db.commit();db.refresh(user);db.add(Audit(actor_id=user.id,action="bootstrap_admin",subject=configured));db.commit()
    return {"token":token_for(user),"user":{"id":user.id,"email":user.email,"display_name":user.display_name,"role":user.role}}
@app.post("/api/auth/login")
def login(data:LoginIn,db:Session=Depends(get_db)):
    user=db.scalar(select(User).where(User.email==str(data.email).lower()))
    if not user or not pw_ok(data.password,user.password_hash): raise HTTPException(401,"Email or password is incorrect")
    return {"token":token_for(user),"user":{"id":user.id,"email":user.email,"display_name":user.display_name,"role":user.role}}
@app.get("/api/me")
def me(user:User=Depends(current_user)):return {"id":user.id,"email":user.email,"display_name":user.display_name,"role":user.role}
@app.get("/api/me/dashboard")
def dashboard(user:User=Depends(current_user),db:Session=Depends(get_db)):
    total=db.scalar(select(func.count(Match.id)).where(Match.user_id==user.id)) or 0; wins=db.scalar(select(func.count(Score.id)).join(Match,Match.id==Score.match_id).where(Match.user_id==user.id,Score.rating>=4)) or 0
    recent=db.scalars(select(Match).where(Match.user_id==user.id).order_by(Match.created_at.desc()).limit(10)).all()
    return {"matches":total,"strong_answers":wins,"recent":[{"id":m.id,"task_type":m.task_type,"mode":m.mode,"created_at":m.created_at.isoformat()} for m in recent]}

# Each model uses its provider's server-side API key; never expose these secrets in the browser.
PROVIDERS={"openai":"openai","anthropic":"anthropic","gemini":"gemini","deepseek":"deepseek","grok":"xai","ollama":"ollama"}
LABELS={"openai":"ChatGPT","anthropic":"Claude","gemini":"Gemini","deepseek":"DeepSeek","grok":"Grok","ollama":"Ollama"}
ENV_KEYS={"openai":"OPENAI_API_KEY","anthropic":"ANTHROPIC_API_KEY","gemini":"GEMINI_API_KEY","deepseek":"DEEPSEEK_API_KEY","grok":"XAI_API_KEY","ollama":"OLLAMA_BASE_URL"}
MODEL_ENV={"openai":"OPENAI_MODEL","anthropic":"ANTHROPIC_MODEL","gemini":"GEMINI_MODEL","deepseek":"DEEPSEEK_MODEL","grok":"GROK_MODEL","ollama":"OLLAMA_MODEL"}
def _provider_ready(key:str)->bool:
    return bool(os.getenv(ENV_KEYS[key]) and os.getenv(MODEL_ENV[key]))

async def _sdk_call(key:str,prompt:str)->str:
    provider=PROVIDERS[key]; model=os.getenv(MODEL_ENV[key],"")
    if not model: raise RuntimeError(f"Set {MODEL_ENV[key]} to an active provider model identifier")
    secret=os.environ[ENV_KEYS[key]]
    def run():
        if provider=="ollama":
            from openai import OpenAI
            client=OpenAI(api_key=os.getenv("OLLAMA_API_KEY","ollama"),base_url=secret.rstrip("/"),timeout=50,max_retries=0)
            return client.chat.completions.create(model=model,messages=[{"role":"user","content":prompt}],max_tokens=1200).choices[0].message.content or ""
        if provider=="openai":
            from openai import OpenAI
            client=OpenAI(api_key=secret,timeout=45,max_retries=1)
            return client.responses.create(model=model,input=prompt,max_output_tokens=1200).output_text or ""
        if provider=="anthropic":
            from anthropic import Anthropic
            result=Anthropic(api_key=secret,timeout=45,max_retries=1).messages.create(model=model,max_tokens=1200,messages=[{"role":"user","content":prompt}])
            return "".join(block.text for block in result.content if getattr(block,"type",None)=="text")
        if provider=="gemini":
            from google import genai
            return genai.Client(api_key=secret).models.generate_content(model=model,contents=prompt).text or ""
        from openai import OpenAI
        if provider=="deepseek":
            client=OpenAI(api_key=secret,base_url="https://api.deepseek.com",timeout=45,max_retries=1)
            return client.chat.completions.create(model=model,messages=[{"role":"user","content":prompt}],max_tokens=1200).choices[0].message.content or ""
        client=OpenAI(api_key=secret,base_url="https://api.x.ai/v1",timeout=45,max_retries=1)
        return client.responses.create(model=model,input=prompt,max_output_tokens=1200).output_text or ""
    return await asyncio.to_thread(run)
async def _compete(key:str,prompt:str,task_type:str,tests:list[dict])->dict:
    started=time.perf_counter(); live=os.getenv("AI_MODE","replay").lower()=="live" and _provider_ready(key)
    if live:
        try:
            body=await asyncio.wait_for(_sdk_call(key,prompt),timeout=50); latency=(time.perf_counter()-started)*1000; accuracy=None; source="live_unscored"
            if task_type=="coding" and tests:
                accuracy=_run_submission(body,tests); source="sandboxed_tests"
            elif task_type in ("factual","creative"):
                judge=os.getenv("JUDGE_PROVIDER","")
                judge_key=next((p for p in [judge,"openai","anthropic","gemini"] if p and p!=key and os.getenv(ENV_KEYS.get(p,""))),None)
                if judge_key:
                    rubric=("Assess factual correctness." if task_type=="factual" else "Assess coherence, originality, and adherence to the task constraints.")
                    try:
                        judged=await _sdk_call(judge_key,"Return only JSON {accuracy: number 0..1, reason: string}. Task: "+prompt+"\nAnswer: "+body+"\nRubric: "+rubric)
                        match=re.search(r"\{.*\}",judged,re.S); data=json.loads(match.group(0)) if match else {}; accuracy=max(0,min(1,float(data["accuracy"]))); source="independent_judge"
                    except Exception: pass
            return {"key":key,"label":LABELS[key],"body":body,"latency_ms":round(latency,1),"accuracy":accuracy,"source":source,"state":"ok","error":None}
        except Exception as exc:
            return {"key":key,"label":LABELS[key],"body":"","latency_ms":round((time.perf_counter()-started)*1000,1),"accuracy":None,"source":"live","state":"error","error":"Provider request failed. Check its server-side configuration and availability."}
    return {"key":key,"label":LABELS[key],"body":"","latency_ms":round((time.perf_counter()-started)*1000,1),"accuracy":None,"source":"unavailable","state":"unconfigured","error":"Live provider is not configured on the server."}


# A constrained Python interpreter for contest code. It accepts small pure functions,
# supports bounded range loops, and never executes arbitrary Python or imports modules.
def _run_submission(text:str,tests:list[dict])->float:
    import ast,operator
    if not tests:return 0.0
    try:
        code=re.sub(r"^```(?:python)?\s*|\s*```$","",text.strip(),flags=re.I)
        tree=ast.parse(code)
        fn=next(n for n in tree.body if isinstance(n,(ast.FunctionDef,)))
        if fn.decorator_list or fn.args.vararg or fn.args.kwarg or fn.args.kwonlyargs: return 0.0
        allowed=(ast.FunctionDef,ast.arguments,ast.arg,ast.Return,ast.Assign,ast.AnnAssign,ast.AugAssign,ast.For,ast.If,ast.Expr,ast.Name,ast.Load,ast.Store,ast.Constant,ast.Tuple,ast.List,ast.BinOp,ast.UnaryOp,ast.Compare,ast.Call,ast.Add,ast.Sub,ast.Mult,ast.Div,ast.FloorDiv,ast.Mod,ast.Pow,ast.USub,ast.UAdd,ast.Eq,ast.NotEq,ast.Lt,ast.LtE,ast.Gt,ast.GtE,ast.Gt,ast.IfExp,ast.BoolOp,ast.And,ast.Or)
        if any(not isinstance(n,allowed) for n in ast.walk(fn)) or any(isinstance(n,ast.Name) and n.id.startswith("__") for n in ast.walk(fn)):return 0.0
        ops={ast.Add:operator.add,ast.Sub:operator.sub,ast.Mult:operator.mul,ast.Div:operator.truediv,ast.FloorDiv:operator.floordiv,ast.Mod:operator.mod,ast.Pow:operator.pow,ast.Eq:operator.eq,ast.NotEq:operator.ne,ast.Lt:operator.lt,ast.LtE:operator.le,ast.Gt:operator.gt,ast.GtE:operator.ge}
        def ev(node,env):
            if isinstance(node,ast.Constant):return node.value
            if isinstance(node,ast.Name):
                if node.id not in env:raise ValueError("unknown name")
                return env[node.id]
            if isinstance(node,(ast.Tuple,ast.List)):return [ev(x,env) for x in node.elts]
            if isinstance(node,ast.BinOp):
                a,b=ev(node.left,env),ev(node.right,env)
                if isinstance(node.op,ast.Pow) and (abs(b)>12 or abs(a)>100000):raise ValueError("exponent limit")
                return ops[type(node.op)](a,b)
            if isinstance(node,ast.UnaryOp):return -ev(node.operand,env) if isinstance(node.op,ast.USub) else +ev(node.operand,env)
            if isinstance(node,ast.Compare):
                left=ev(node.left,env)
                for op,right_node in zip(node.ops,node.comparators):
                    right=ev(right_node,env)
                    if not ops[type(op)](left,right):return False
                    left=right
                return True
            if isinstance(node,ast.BoolOp):
                vals=[bool(ev(v,env)) for v in node.values];return all(vals) if isinstance(node.op,ast.And) else any(vals)
            if isinstance(node,ast.IfExp):return ev(node.body if ev(node.test,env) else node.orelse,env)
            if isinstance(node,ast.Call) and isinstance(node.func,ast.Name) and node.func.id=="range":
                args=[int(ev(a,env)) for a in node.args]; result=range(*args)
                if len(result)>10000:raise ValueError("loop limit")
                return result
            raise ValueError("unsupported expression")
        class Returned(Exception):
            def __init__(self,value):self.value=value
        def assign(target,value,env):
            if isinstance(target,ast.Name):env[target.id]=value
            elif isinstance(target,(ast.Tuple,ast.List)) and len(target.elts)==len(value):
                for t,v in zip(target.elts,value):assign(t,v,env)
            else:raise ValueError("unsupported assignment")
        def exec_block(stmts,env):
            for stmt in stmts:
                if isinstance(stmt,ast.Return):raise Returned(ev(stmt.value,env) if stmt.value else None)
                if isinstance(stmt,ast.Assign):
                    value=ev(stmt.value,env)
                    for target in stmt.targets:assign(target,value,env)
                elif isinstance(stmt,ast.AnnAssign):assign(stmt.target,ev(stmt.value,env),env)
                elif isinstance(stmt,ast.AugAssign):assign(stmt.target,ops[type(stmt.op)](ev(stmt.target,env),ev(stmt.value,env)),env)
                elif isinstance(stmt,ast.If):exec_block(stmt.body if ev(stmt.test,env) else stmt.orelse,env)
                elif isinstance(stmt,ast.For):
                    for value in ev(stmt.iter,env):assign(stmt.target,value,env);exec_block(stmt.body,env)
                elif isinstance(stmt,ast.Expr):ev(stmt.value,env)
                else:raise ValueError("unsupported statement")
        passed=0
        for case in tests[:100]:
            try:
                env={a.arg:v for a,v in zip(fn.args.args,case.get("args",[]))}
                exec_block(fn.body,env);raise ValueError("function did not return")
            except Returned as result:
                if result.value==case.get("expected"):passed+=1
            except Exception:pass
        return passed/len(tests[:100])
    except Exception:return 0.0

@app.post("/api/arena/matches")
async def arena_match(data:ArenaIn,user:User=Depends(current_user),db:Session=Depends(get_db)):
    if data.task_type not in ("coding","factual","creative"):raise HTTPException(422,"task_type must be coding, factual, or creative")
    if data.task_type=="coding" and not data.tests:raise HTTPException(422,"Coding matches require explicit test cases; code is evaluated by the restricted interpreter")
    recent_count=db.scalar(select(func.count(Match.id)).where(Match.user_id==user.id,Match.created_at>=datetime.now(timezone.utc).replace(tzinfo=None)-timedelta(minutes=1))) or 0
    if recent_count>=3:raise HTTPException(429,"Arena limit reached. Try again in one minute.")
    results=await asyncio.gather(*[_compete(k,data.prompt,data.task_type,data.tests) for k in LABELS])
    record=Match(id=str(uuid.uuid4()),user_id=user.id,prompt=data.prompt,task_type=data.task_type,mode="live" if any(x["state"]=="ok" and x["source"]!="replay_fixture" for x in results) else "unavailable")
    db.add(record);db.flush()
    for result in results:
        response=Response(match_id=record.id,model_key=result["key"],body=result["body"],latency_ms=result["latency_ms"],state=result["state"],error=result["error"]);db.add(response)
        accuracy=result["accuracy"]; final=(accuracy*0.8 - min(result["latency_ms"]/30000,1)*0.2) if accuracy is not None else None
        db.add(Score(match_id=record.id,model_key=result["key"],accuracy=accuracy,final_score=final,source=result["source"]))
    db.commit()
    return {"id":record.id,"mode":record.mode,"task_type":record.task_type,"responses":results}
@app.get("/api/arena/history")
def arena_history(user:User=Depends(current_user),db:Session=Depends(get_db)):
    matches=db.scalars(select(Match).where(Match.user_id==user.id).order_by(Match.created_at.desc()).limit(50)).all()
    return [{"id":m.id,"prompt":m.prompt,"task_type":m.task_type,"mode":m.mode,"created_at":m.created_at.isoformat(),"responses":[{"model_key":r.model_key,"body":r.body,"latency_ms":r.latency_ms,"state":r.state} for r in db.scalars(select(Response).where(Response.match_id==m.id)).all()]} for m in matches]
@app.post("/api/arena/{match_id}/rate")
def rate_answer(match_id:str,data:RateIn,user:User=Depends(current_user),db:Session=Depends(get_db)):
    match=db.get(Match,match_id)
    if not match or match.user_id!=user.id:raise HTTPException(404,"Match not found")
    response=db.scalar(select(Response).where(Response.match_id==match_id,Response.model_key==data.model_key))
    if not response:raise HTTPException(404,"Response not found")
    if response.state!="ok":raise HTTPException(409,"Cannot rate an answer that was not returned by a provider")
    score=db.scalar(select(Score).where(Score.match_id==match_id,Score.model_key==data.model_key))
    if not score:raise HTTPException(404,"Answer score not found")
    score.rating=data.rating
    db.add(Audit(actor_id=user.id,action="rated_ai_answer",subject=f"{match_id}:{data.model_key}:{data.rating}"));db.commit()
    return {"saved":True,"rating":data.rating}
