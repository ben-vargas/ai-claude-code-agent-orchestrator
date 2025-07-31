# ⚠️ DANGEROUS RULES - USE AT YOUR OWN RISK ⚠️

## 🚨 CRITICAL WARNING 🚨

These Claude Code rules files are designed for **CONTROLLED ENVIRONMENTS ONLY** and provide agents with extensive permissions that could:

- **DELETE OR MODIFY ANY FILES** on your system
- **EXECUTE SYSTEM COMMANDS** with minimal restrictions
- **ACCESS NETWORK RESOURCES** without approval
- **INSTALL OR REMOVE SOFTWARE** without confirmation
- **MODIFY SYSTEM CONFIGURATIONS** automatically

## ⛔ DISCLAIMER

**BY USING THESE RULES, YOU ACKNOWLEDGE THAT:**

1. **YOU ARE SOLELY RESPONSIBLE** for any damage, data loss, or security breaches
2. **W4M.AI AND CONTRIBUTORS PROVIDE NO WARRANTY** and accept no liability
3. **THESE FILES ARE EXAMPLES ONLY** for demonstration in isolated environments
4. **YOU SHOULD NEVER USE THESE** on production systems or with sensitive data
5. **YOU HAVE BEEN WARNED** about the potential risks

## 🛡️ Safety Measures

While these rules are permissive, they still block the most catastrophic commands:

### Blocked Patterns:
- `rm -rf /` and variants
- `rm -rf /*`
- `dd if=/dev/zero of=/dev/sda` (disk wiping)
- `:(){ :|:& };:` (fork bombs)
- `chmod -R 000 /`
- `mkfs` commands on system drives
- `> /dev/sda` (direct disk writes)

## 📁 Available Rule Sets

### 1. `permissive-dev-rules.json`
- For development environments
- Allows file operations without confirmation
- Permits package installation
- Enables git operations freely

### 2. `automation-rules.json`
- For CI/CD and automation
- Allows unattended execution
- Permits system modifications
- Enables service management

### 3. `research-rules.json`
- For research and experimentation
- Allows broad file system access
- Permits network operations
- Enables data collection

## 🔧 Installation (NOT RECOMMENDED)

**DO NOT INSTALL THESE IN YOUR MAIN CLAUDE CODE CONFIGURATION**

If you absolutely must use these in an isolated environment:

```bash
# Create an isolated Claude Code profile
mkdir -p ~/.claude-dangerous/rules

# Copy the rules you need
cp dangerous-rules/permissive-dev-rules.json ~/.claude-dangerous/rules/

# Run Claude Code with alternate config
CLAUDE_CONFIG_DIR=~/.claude-dangerous claude
```

## 🏷️ Better Alternatives

Instead of using these dangerous rules, consider:

1. **Using Docker/VMs**: Run agents in isolated containers
2. **Temporary Environments**: Use cloud workspaces that can be destroyed
3. **Granular Permissions**: Create specific rules for your use case
4. **Human Oversight**: Keep confirmation prompts for critical operations

## 📝 Example Use Cases

These rules were created for:
- Automated testing in disposable VMs
- Research in sandboxed environments  
- Development on isolated machines
- Demonstration purposes only

## ⚖️ Legal Notice

THESE FILES ARE PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

---

**Remember**: With great power comes great responsibility. These rules remove many safety guards. Use them only when you fully understand and accept the risks.