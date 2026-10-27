# AI ARENA verification

1. With no API URL, verify the disconnected state and no sample answers.
2. Configure an invalid HTTPS URL; verify offline status and no credential exposure.
3. With a live API, register and sign in; refresh and check that the session token is not persistent.
4. Submit a prompt; verify each provider independently shows a live response or failure. No replay is counted as live.
5. Rate a live answer and confirm the saved vote and account record.
6. Confirm match history is scoped to the signed-in account.
7. Test speech transcription where supported and typed prompts otherwise.
8. Check phone, tablet, desktop, keyboard navigation, dialogs, and reduced motion.

