# 📦 What is this?
This folder contains the customized configuration for Continue in your project:
- Editor preferences
- Language model configurations
- System environment variables
- Session temporary files

# Prerequisites
- Have the Continue extension installed in your editor
- Have run ./WorkflowSetup.sh or ./WorkflowSetup.ps1

# ✅ What to do
## **Install the Continue extension:**
If you don't have the Continue extension installed, install it using the steps at this link:
- [Official Continue documentation](https://docs.continue.dev/ide-extensions/install)

## **First time you see this folder:**
```bash
# Copy this folder to the root of your project
cp -r .continue/ /path/to/your/project/

# Alternative from the current folder into the target project
mkdir -p .continue
cp -r /current/path/.continue/* .continue/
```

# 📚 Additional documentation
- [Official Continue documentation](https://continue.dev/docs)
- [Configuration examples](https://github.com/continuedev/continue)
