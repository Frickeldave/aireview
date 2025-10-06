# Automated Code Review System

Ein vollautomatisiertes Code Review System mit **AI Hub** Integration.

## 🚀 Features

✅ **One-File Output** - Eine einzige, vollständige Markdown-Review-Datei  
✅ **AI-Powered Reviews** - AI Hub Integration für automatische Code-Analysen  
✅ **Management Summary** - KI-generierte Zusammenfassungen für Führungskräfte  
✅ **Consolidated Reports** - Alle Informationen in einer strukturierten Datei  
✅ **Erweiterte Logging-Funktionen** - Debug-Logs, Request/Response-Speicherung  
✅ **Konfigurierbare Diff-Kürzung** - Anpassbare Limits für große Änderungen  
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
results/25-09-26_14-44_complete-review-feat-my-silly-change.md
```

Ein komplettes Beispiel eines Review-Ergebnisses findet du [hier](./complete-review-example.md).

**Zusätzlich generierte Debug-Dateien:**
```
logs/25-09-26_14-44_review-log-feat-my-silly-change.log
logs/25-09-26_14-44_ai-request-feat-my-silly-change.json
logs/25-09-26_14-44_ai-response-feat-my-silly-change.json
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
    "diff_max_chars": 10000,
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

#### 📋 **Neue Konfigurationsoption: `diff_max_chars`**

Konfiguriert die maximale Anzahl der Zeichen, die vom Diff zur AI-Analyse gesendet werden:

**Standard-Konfiguration** (empfohlen):
```json
{
  "ai": {
    "diff_max_chars": 10000    // 10.000 Zeichen Limit für API-Kompatibilität
  }
}
```

**Vollständige Analyse** (keine Kürzung):
```json
{
  "ai": {
    "diff_max_chars": 0        // Keine Kürzung, vollständiger Diff
  }
}
```

**Konservative Einstellung**:
```json
{
  "ai": {
    "diff_max_chars": 5000     // Kleineres Limit für strikte API-Constraints
  }
}
```

**Wichtige Hinweise:**
- ✅ **Standard `10000`**: Guter Kompromiss zwischen Detail und API-Kompatibilität
- ⚠️ **`0` (keine Kürzung)**: Kann bei großen Diffs zu API-Fehlern führen  
- 🔍 **Debug-Logs**: Zeigen an, ob und wie der Diff gekürzt wurde

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
- `ai.diff_max_chars` - Diff-Kürzungs-Limit (optional, Standard: 10000)

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
[2025-09-26 10:56:09] 🚀 Starting automated code review for branch: feat/user-authentication
[2025-09-26 10:56:09] ✅ Repository cloned successfully
[2025-09-26 10:56:09] ⚠️ Diff zu groß (19475 chars), gekürzt auf 10000 chars
[2025-09-26 10:56:09] ✅ AI-Review erfolgreich erstellt (1247 characters)
[2025-09-26 10:56:09] 📋 Einzige Review-Datei erstellt: 25-09-26_10-56_complete-review-feat-user-authentication.md
[2025-09-26 10:56:09] 🎉 Review completed! Check results in: results/

📝 **Key Review Points:**
🔴 **Large Change** - High complexity, thorough review required
⚙️ Configuration files changed - Review for security
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
├── complete-review-example.md   # Vollständiges Beispiel-Review
├── README.md                    # Diese Dokumentation
├── results/                     # Generierte Review-Dateien
│   └── YY-MM-DD_HH-MM_complete-review-BRANCH.md
├── logs/                        # Debug- und Logging-Dateien
│   ├── YY-MM-DD_HH-MM_review-log-BRANCH.log       # Haupt-Log
│   ├── YY-MM-DD_HH-MM_ai-request-BRANCH.json      # API-Requests
│   └── YY-MM-DD_HH-MM_ai-response-BRANCH.json     # API-Responses
└── checkout/                    # Temporäre Git-Checkouts (automatisch bereinigt)
    └── ts-mono-repo-BRANCH/     # Temporärer Git-Clone
```

## 🔧 Troubleshooting

### Script startet nicht

```bash
# Permissions prüfen
ls -la review.sh
chmod +x review.sh

# Syntax prüfen  
bash -n review.sh

# Log-Dateien nach fehlgeschlagenen Versuchen prüfen
ls -la logs/
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

### Diff zu groß für AI-Analyse

```bash
# Warnung in der Konsole:
[2025-09-26 11:23:45] ⚠️ Diff zu groß (25000 chars), gekürzt auf 10000 chars
```

**Lösungsansätze:**
1. **Standard-Verhalten beibehalten** - 10.000 Zeichen sind meist ausreichend
2. **Kürzung deaktivieren** für vollständige Analyse:
   ```json
   {
     "ai": {
       "diff_max_chars": 0
     }
   }
   ```
3. **Limit anpassen** je nach AI-Hub Kapazität:
   ```json
   {
     "ai": {
       "diff_max_chars": 15000
     }
   }
   ```

**Debug-Informationen:** Die Log-Dateien in `logs/` enthalten Details zur Diff-Verarbeitung

## 📈 Advanced Features

### 🔧 Erweiterte Logging-Funktionen

Das System bietet umfassendes Debug-Logging für Troubleshooting:

```bash
# Log-Dateien werden automatisch erstellt:
logs/
├── 25-09-26_11-23_review-log-BRANCH.log           # Haupt-Log mit allen Details
├── 25-09-26_11-23_ai-request-BRANCH.json          # API-Request Payload  
└── 25-09-26_11-23_ai-response-BRANCH.json         # API-Response Details
```

**Log-Level:**
- **Console**: Wichtige Informationen (80 Zeichen optimiert)
- **DEBUG**: Detaillierte technische Informationen (nur in Datei)
- **ERROR**: Fehler mit Stack-Traces für Debugging

### ⚙️ Konfigurierbare Diff-Verarbeitung

**Intelligente Diff-Kürzung** basierend auf `diff_max_chars`:

```bash
# Bei großen Diffs:
[2025-09-26 11:23:45] ⚠️ Diff zu groß (19475 chars), gekürzt auf 10000 chars
[DEBUG] Diff max chars config: 10000
[DEBUG] Original diff size: 19475 characters  
[DEBUG] Limited diff size: 10045 characters
[DEBUG] Diff truncated: yes
```

**Verwendungsfälle:**
- **Große Refactorings**: `diff_max_chars: 0` für vollständige Analyse
- **API-Limits**: `diff_max_chars: 5000` für strikte Limits  
- **Standard-Reviews**: `diff_max_chars: 10000` (empfohlen)

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
3. **Log-Dateien checken** - Debug-Informationen in `logs/`
4. **Review-Dateien checken** - Auch bei Fehlern wird meist eine Datei erstellt
5. **Git-Repository Issues** - Für Bug Reports und Feature Requests

## 📦 Dependencies

**Erforderliche Tools:**
- **git** - Für Repository-Operations
- **jq** - Für JSON-Parsing der Config-Datei
- **curl** - Für API-Aufrufe (bereits auf den meisten Systemen installiert)

### jq Installation:
```bash
# Ubuntu/Debian
sudo apt-get install jq

# macOS
brew install jq

# CentOS/RHEL
sudo yum install jq
```
