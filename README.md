# Automated Code Review System

Ein vollautomatisiertes Code Review System mit **AI Hub** Integration.

## 🚀 Features

✅ **One-File Output** - Eine einzige, vollständige Markdown-Review-Datei  
✅ **AI-Powered Reviews** - AI Hub Integration für automatische Code-Analysen  
✅ **Management Summary** - KI-generierte Zusammenfassungen für Führungskräfte  
✅ **Consolidated Reports** - Alle Informationen in einer strukturierten Datei  
✅ **80-Char Console Logging** - Optimierte Konsolen-Ausgabe  
✅ **Zeitstempel-basierte Benennung** - Dateien mit YY-MM-DD_HH-MM Prefix  
✅ **Sichere Konfiguration** - Git-Credentials in externer JSON-Datei  
✅ **Azure DevOps Integration** - Direkter Repository-Support

## 📋 Quick Start

```bash
# Automatisches Review eines Branches
./review.sh <BRANCHNAME>

# Beispiel  
./review.sh feat/my-silly-change
```

**Ergebnis:** Eine einzige Markdown-Datei mit vollständigem Review:
```
results/25-09-25_14-44_my-silly-change.md
```

## 📄 Generierte Review-Datei

Das System erstellt **eine einzige, vollständige Markdown-Datei** mit folgender Struktur:

### � Dateistruktur

```markdown
# Vollständige Code-Review: <BRANCH-NAME>

## 📋 Inhaltsverzeichnis
1. Management Summary
2. Übersichtstabelle  
3. AI-Review
4. Technische Details
5. Code-Änderungen (Diff)

## Management Summary
- KI-generierte Zusammenfassung für Führungskräfte
- Qualitätsbewertung und Risikobewertung
- Konkrete Deployment-Empfehlungen

## Übersichtstabelle
- Branch, Autor, Dateien geändert
- Zeilen hinzugefügt/entfernt
- Test- und Konfigurationsstatus

## AI-Review  
- Vollautomatische Code-Analyse durch AI Hub
- Deutsche Sprache, professionelle Struktur
- Code-Qualität, Security, Performance Assessment

## Technische Details
- Branch-Informationen und Metadaten
- Commit-Historie und Merge-Base

## Code-Änderungen (Diff)
- Liste der geänderten Dateien
- Vollständiger, kollabierbar Diff-Inhalt
```

## 🤖 AI-Integration: AI Hub

Das System nutzt den **AI Hub** für vollautomatische AI-Reviews:

### 🔧 Konfiguration (review.json)

```json
{
  "git": {
    "username": "your-username",
    "password": "your-personal-access-token"
  },
  "repository": {
    "url": "https://dev.azure.com/org/project/_git/repo"
  },
  "ai": {
    "useAI": true,
    "adesso_hub": {
      "url": "https://.../...",
      "api_key": "...",
      "model": "gpt-oss-120b-sovereign",
      "max_tokens": 2000,
      "temperature": 0.3
    }
  }
}
```

**Vorteile der AI Hub Integration:**

✅ **Vollautomatisch** - Echte AI-Analyse ohne manuelle Schritte  
✅ **Unternehmens-KI** - Sichere, interne AI-Lösung von Adesso  
✅ **Deutsche Sprache** - AI-Reviews auf Deutsch  
✅ **Hohe Qualität** - Strukturierte, professionelle Code-Analysen  
✅ **Management Summary** - KI-generierte Zusammenfassungen für Führungskräfte  
✅ **Ausfallsicher** - Graceful Fallback wenn Hub nicht erreichbar

## 🔍 AI Review Analyse-Bereiche

Die AI Hub Reviews analysieren systematisch:

### 🔍 **Code Quality Analysis**
- Coding Standards und Best Practices  
- Code-Komplexität und Lesbarkeit  
- Architektur-Patterns und Design-Entscheidungen

### 🛡️ **Security Review**  
- Potentielle Sicherheitslücken  
- Input-Validierung und Sanitizing  
- Authentication und Authorization Issues

### ⚡ **Performance Assessment**
- Algorithmus-Effizienz  
- Memory-Management  
- Database-Query Optimierung

### 🧪 **Best Practices Check**
- Einhaltung von Coding Standards  
- Test-Coverage und Test-Qualität  
- Dokumentation und Code-Kommentare

### 🏗️ **Architecture Review**
- Design-Entscheidungen und Patterns  
- API-Design und Schnittstellen  
- Modulstruktur und Dependencies

### ⚖️ **Risk Assessment & Management Summary**
- Potentielle Risiken und Mitigation  
- Change-Impact Analyse  
- **Management Summary** für Führungskräfte mit Deployment-Empfehlungen

## ⚙️ Setup & Konfiguration

### 1. Repository Setup
      ```bash
git clone <this-repo>
cd aireview
```

### 2. Konfiguration erstellen

```bash
# Template kopieren und anpassen
cp review.template.json review.json

# Konfiguration bearbeiten
nano review.json
```

**Erforderliche Anpassungen in `review.json`:**
- `git.username` - Ihr Azure DevOps Username
- `git.password` - Personal Access Token  
- `repository.url` - URL zu Ihrem Azure DevOps Repository
- `ai.adesso_hub.api_key` - Ihr AI Hub API Key (falls verfügbar)

### 3. Dependencies prüfen

```bash
# Erforderliche Tools
which git    # ✅ Git installiert
which jq     # ✅ jq für JSON-Parsing
which curl   # ✅ curl für API-Calls

# Falls jq fehlt:
sudo apt-get install jq  # Ubuntu/Debian  
brew install jq          # macOS
```

### 4. Script ausführbar machen

```bash
chmod +x review.sh
```

## 🚀 Usage Examples

### Einfaches Review

```bash
./review.sh feat/user-authentication
```

**Output:**
```
[2025-09-25 14:45:54] 🚀 Starting automated code review for branch: feat/user-authentication
[2025-09-25 14:45:54] ✅ Repository cloned successfully
[2025-09-25 14:45:54] ✅ AI-Review erfolgreich erstellt  
[2025-09-25 14:45:54] 📋 Einzige Review-Datei erstellt: 25-09-25_14-45_complete-review-feat-user-authentication.md
[2025-09-25 14:45:54] 🎉 Review completed! Check results in: results/
```

### Review mit großen Änderungen

```bash
./review.sh feat/major-refactoring-TICKET-123
```

**Erwartete Ergebnisse:**
- 🔴 **Large Change** - Umfassende Prüfung erforderlich
- 📋 **Management Summary** mit Risikobewertung
- ⚠️ **Deployment-Empfehlungen** für stufenweises Rollout

## 📁 Dateistruktur

```
aireview/
├── review.sh                    # Haupt-Script
├── review.json                  # Konfiguration (nicht in Git!)  
├── review.template.json         # Template für Konfiguration
├── results/                     # Generierte Review-Dateien
│   └── YY-MM-DD_HH-MM_complete-review-BRANCH.md
├── checkout/                    # Temporäre Git-Checkouts
└── README.md                    # Diese Dokumentation
```

## 🔧 Troubleshooting

### Script startet nicht

```bash
# Permissions prüfen
ls -la review.sh
chmod +x review.sh

# Syntax prüfen  
bash -n review.sh
```

### Git Authentication Fehler

```bash
# PAT prüfen
git ls-remote https://username:token@dev.azure.com/org/project/_git/repo

# Konfiguration validieren
jq . review.json
```

### AI-Hub nicht erreichbar

```bash
# Status in der generierten Review-Datei:
## AI-Review
⚠️ AI-Hub Response invalid or empty
AI-Review konnte nicht erstellt werden - ungültige Antwort vom Hub.
```

**Lösungsansätze:**
- API-Key in `review.json` prüfen
- AI Hub Verfügbarkeit testen
- Als Fallback wird trotzdem ein vollständiges Review erstellt

## 📈 Advanced Features

### Console Output Optimization

Das System nutzt **80-Zeichen Logging** für optimale Konsolen-Lesbarkeit:

```bash  
[2025-09-25 14:45:54] 🚀 Starting automated code review for branch: feat/add-test...
[2025-09-25 14:45:54] ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[2025-09-25 14:45:54] ✅ Repository cloned successfully
```

### Management Summary Generation

Automatische Generierung von **Management Summaries** für Führungskräfte:

- **Was wurde geändert** - Zusammenfassung der Änderungen
- **Qualitätsbewertung** - Risiko-Assessment (Niedrig/Mittel/Hoch)  
- **Empfehlung** - Konkrete Deployment-Empfehlungen
- **Nächste Schritte** - Actionable Items für das Team

---

## 📞 Support

Bei Fragen oder Problemen:

1. **README.md durchlesen** - Häufige Probleme sind hier dokumentiert
2. **Script-Output prüfen** - Detaillierte Fehlermeldungen in der Konsole  
3. **Review-Dateien checken** - Auch bei Fehlern wird meist eine Datei erstellt
4. **Git-Repository Issues** - Für Bug Reports und Feature Requests
- **jq** - Für JSON-Parsing der Config-Datei
- **curl** - Für API-Aufrufe (bereits auf den meisten Systemen installiert)
- **Optional:** OpenAI API-Key für beste AI-Review Qualität

### jq Installation:
```bash
# Ubuntu/Debian
sudo apt-get install jq

# macOS
brew install jq

# CentOS/RHEL
sudo yum install jq
```

## GitHub Copilot Integration

### Direkte Verwendung:
```bash
./review.sh feat/my-branch
```

### Über GitHub Copilot Chat:
```
Führe ein Code Review für den Branch "feat/my-branch" aus
```

**Das System generiert automatisch:**
1. Vollständige Diff-Analyse
2. Statistische Auswertung  
3. Strukturiertes Review mit Empfehlungen
4. **Komplette AI-Analyse durch GPT-4** (bei konfiguriertem API-Key)

## Setup für AI-Reviews

### OpenAI API-Key einrichten:

1. **API-Key generieren:**
   - Gehen Sie zu [platform.openai.com](https://platform.openai.com)
   - Erstellen Sie einen API-Key

2. **Konfiguration aktualisieren:**
```json
{
  "ai": {
    "openai_api_key": "sk-proj-your-actual-api-key-here",
    "model": "gpt-4",
    "enabled": true
  }
}
```

3. **Testen:**
```bash
./review.sh test-branch
# Prüfen Sie die generierte ai-review Datei auf echte AI-Inhalte
```

## Ausgabe-Beispiel mit AI-Review

```
🚀 Starting automated code review for branch: feat/add-user-auth
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[2024-12-08 14:30:15] 📡 Cloning repository...
[2024-12-08 14:30:45] ✅ Repository cloned successfully
[2024-12-08 14:30:46] 📂 Checking out branch: feat/add-user-auth
[2024-12-08 14:30:47] 🎯 Finding branch point from develop...
[2024-12-08 14:30:48] 📋 Generating comprehensive code review...
[2024-12-08 14:30:49] 🤖 Trying direct OpenAI API call with model: gpt-4...
[2024-12-08 14:30:52] ✅ OpenAI API responded successfully with gpt-4
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ CODE REVIEW COMPLETED SUCCESSFULLY
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📋 **Review Summary for feat/add-user-auth**
👤 Author: John Doe
📁 Files Changed: 12
➕ Lines Added: 458
➖ Lines Removed: 23
💾 Net Change: 435 lines

📝 **Generated Files:**
✅ 24-12-08_14-30_branch-diff-feat-add-user-auth.patch
✅ 24-12-08_14-30_branch-summary-feat-add-user-auth.txt
✅ 24-12-08_14-30_branch-review-feat-add-user-auth.md
✅ 24-12-08_14-30_ai-review-feat-add-user-auth.md (AI-Generated by GPT-4)

📝 **Key Review Points:**
🔴 **Large Change** - High complexity, thorough review required
✅ Tests were added or modified - Good practice!
📦 Dependencies changed - Verify compatibility
🤖 **AI Analysis Complete** - Detailed review available in ai-review file
```

**Die ai-review Datei enthält dann:**
- Executive Summary mit Risk Assessment
- Detaillierte Code-Quality Analyse durch GPT-4
- Spezifische Security und Performance Empfehlungen  
- Konkrete Verbesserungsvorschläge
- Finale Approval-Empfehlung (APPROVE/NEEDS_CHANGES/REJECT)

## Troubleshooting

### AI-Reviews funktionieren nicht

1. **OpenAI API-Key testen:**
```bash
curl -H "Authorization: Bearer sk-your-key" https://api.openai.com/v1/models
```

2. **Konfiguration prüfen:**
```bash
jq '.ai' review.json
```

3. **Log-Output analysieren:**
```bash
./review.sh branch-name 2>&1 | grep "🤖\|⚠️\|✅"
```

### Häufige Probleme
- **"jq command not found"** → `sudo apt-get install jq`
- **"AI service not available"** → API-Key oder CLI-Installation prüfen
- **"OpenAI API call failed"** → API-Key und Guthaben prüfen
- **"Permission denied"** → `chmod +x review.sh`

```
