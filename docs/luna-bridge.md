## Luna Bridge Documentation

### Architecture

Hermes → Luna-bridge → Luna-chatgpt → BrowserSkill → Chrome → ChatGPT

### Dedicated Chrome Profile

- Profile: 8ef5e368
- Manual authentication by user
- Credentials not passed to Hermes
- BrowserSkill uses existing ChatGPT tab
- Session is temporary and stops after task

### Tests

- LUNA_BRIDGE_OK
- LUNA_AUDIT_OK