#!/bin/bash

# Automated Code Review System for GitHub Copilot
# All-in-one Bash solution without external dependencies
# Usage: ./review.sh <BRANCH_NAME>
#
# This script:
# 1. Clones the repository and checks out the branch
# 2. Creates diff and summary files
# 3. Analyzes the changes and generates a comprehensive review
# 4. Cleans up temporary files
# 5. Outputs the review to console and saves to file

set -e  # Exit on any error

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/review.json"

# Check if branch name is provided
if [ $# -eq 0 ]; then
    echo "❌ Error: Branch name is required as parameter"
    echo "Usage: $0 <BRANCH_NAME>"
    echo ""
    echo "Example: $0 feat/my-feature-branch"
    exit 1
fi

BRANCH_NAME="$1"
# Generate timestamp prefix in format yy-mm-dd_hh-mm
DATE_PREFIX=$(date '+%y-%m-%d_%H-%M')
# Normalize branch name for directory creation (replace / with -)
BRANCH_NAME_NORMALIZED=$(echo "$BRANCH_NAME" | sed 's/\//-/g')
TARGET_DIR="$SCRIPT_DIR/checkout/ts-mono-repo-$BRANCH_NAME_NORMALIZED"
RESULTS_DIR="$SCRIPT_DIR/results"

# Function to log messages with timestamp (max 80 chars)
log() {
    local timestamp="[$(date '+%Y-%m-%d %H:%M:%S')]"
    local message="$1"
    local max_length=80
    local available_length=$((max_length - ${#timestamp} - 1))
    
    if [ ${#message} -gt $available_length ]; then
        echo "$timestamp ${message:0:$available_length}..."
    else
        echo "$timestamp $message"
    fi
}

# Function to cleanup on exit
cleanup() {
    if [ $? -ne 0 ]; then
        log "❌ Script failed. Check the error messages above."
    fi
}
trap cleanup EXIT

# Check if config file exists
if [ ! -f "$CONFIG_FILE" ]; then
    echo "❌ Error: Configuration file not found: $CONFIG_FILE"
    echo "Please create the file with the following structure:"
    echo "{"
    echo '  "git": {'
    echo '    "username": "your-username",'
    echo '    "password": "your-personal-access-token"'
    echo "  },"
    echo '  "repository": {'
    echo '    "url": "https://your-repo-url"'
    echo "  }"
    echo "}"
    exit 1
fi

# Check if jq is available for JSON parsing
if ! command -v jq &> /dev/null; then
    echo "❌ Error: jq is required but not installed. Please install jq first:"
    echo "sudo apt-get install jq  # For Ubuntu/Debian"
    echo "brew install jq          # For macOS"
    exit 1
fi

# Read credentials and repository URL from JSON file
GIT_USERNAME=$(jq -r '.git.username' "$CONFIG_FILE")
GIT_PASSWORD=$(jq -r '.git.password' "$CONFIG_FILE")
REPO_URL=$(jq -r '.repository.url' "$CONFIG_FILE")

# Read AI configuration for Adesso AI Hub
USE_AI=$(jq -r '.ai.useAI' "$CONFIG_FILE" 2>/dev/null)
ADESSO_HUB_URL=$(jq -r '.ai.adesso_hub.url' "$CONFIG_FILE" 2>/dev/null)
ADESSO_API_KEY=$(jq -r '.ai.adesso_hub.api_key' "$CONFIG_FILE" 2>/dev/null)
ADESSO_MODEL=$(jq -r '.ai.adesso_hub.model' "$CONFIG_FILE" 2>/dev/null)
ADESSO_MAX_TOKENS=$(jq -r '.ai.adesso_hub.max_tokens' "$CONFIG_FILE" 2>/dev/null)
ADESSO_TEMPERATURE=$(jq -r '.ai.adesso_hub.temperature' "$CONFIG_FILE" 2>/dev/null)

# Generate AI Review using Adesso AI Hub
generate_ai_review() {
    local branch_name="$1"
    local commit_author="$2"  
    local commit_message="$3"
    local diff_content="$4"
    
    # Check if AI is enabled
    if [ "$USE_AI" != "true" ]; then
        log "🤖 AI reviews disabled in configuration, skipping AI review generation"
        return 0
    fi
    
    # Check if Adesso AI Hub is configured
    if [ -z "$ADESSO_HUB_URL" ] || [ -z "$ADESSO_API_KEY" ]; then
        log "⚠️ Adesso AI Hub not configured, skipping AI review generation"
        return 0
    fi
    
    log "🤖 Generating AI review using Adesso AI Hub..."
    
    # Create a comprehensive prompt for the AI Hub - limit diff size for API
    local prompt_content=""
    prompt_content+="Führe eine umfassende Code-Review der folgenden Änderungen durch:\n\n"
    prompt_content+="BRANCH: $branch_name\n"
    prompt_content+="AUTOR: $commit_author\n" 
    prompt_content+="COMMIT: $commit_message\n\n"
    
    # Limit diff content to avoid API payload limits (max 10000 chars)
    local limited_diff
    if [ ${#diff_content} -gt 10000 ]; then
        limited_diff="${diff_content:0:10000}\n\n... (Diff gekürzt aufgrund der Größe) ..."
        log "⚠️ Diff zu groß (${#diff_content} chars), gekürzt auf 10000 chars"
    else
        limited_diff="$diff_content"
    fi
    
    prompt_content+="DIFF:\n$limited_diff\n\n"
    prompt_content+="Bitte analysiere:\n"
    prompt_content+="1. Code-Qualität und Best Practices\n"
    prompt_content+="2. Potentielle Bugs oder Sicherheitslücken\n"
    prompt_content+="3. Performance-Aspekte\n"
    prompt_content+="4. Wartbarkeit und Lesbarkeit\n"
    prompt_content+="5. Test-Abdeckung\n\n"
    prompt_content+="Antworte auf Deutsch und strukturiere das Review übersichtlich."
    
    # Create JSON payload - use mktemp for proper temp file
    local temp_request_file=$(mktemp)
    
    # Escape JSON content properly
    local escaped_prompt_content=$(echo "$prompt_content" | jq -Rs .)
    
    cat > "$temp_request_file" << EOF
{
    "model": "$ADESSO_MODEL",
    "messages": [
        {
            "role": "system",
            "content": "Du bist ein erfahrener Senior Software-Entwickler und Code-Reviewer. Analysiere Code-Änderungen professionell und konstruktiv."
        },
        {
            "role": "user", 
            "content": $escaped_prompt_content
        }
    ],
    "max_tokens": 2000,
    "temperature": 0.3
}
EOF

    # Debug: Log request details
    log "📝 API Request Model: $ADESSO_MODEL"
    log "📝 API Request URL: $ADESSO_HUB_URL"  
    log "🔍 Request payload size: $(wc -c < "$temp_request_file") bytes"

    # Make API request to Adesso AI Hub
    local ai_response
    ai_response=$(curl -s \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $ADESSO_API_KEY" \
        -d @"$temp_request_file" \
        "$ADESSO_HUB_URL" 2>/dev/null)
    
    local curl_exit_code=$?
    
    if [ $curl_exit_code -eq 0 ] && [ -n "$ai_response" ]; then
        # Debug: Log response for troubleshooting (first 200 chars)
        local debug_response=$(echo "$ai_response" | head -c 200)
        log "🔍 AI Hub Response (first 200 chars): ${debug_response}..."
        
        # Check if response contains error
        local error_message=$(echo "$ai_response" | jq -r '.error.message // empty' 2>/dev/null)
        if [ -n "$error_message" ]; then
            log "❌ AI-Hub API Error: $error_message"
            echo "AI-Review konnte nicht erstellt werden - API Error: $error_message"
            rm -f "$temp_request_file" 2>/dev/null
            return 1
        fi
        
        # Extract content from API response
        local ai_content
        ai_content=$(echo "$ai_response" | jq -r '.choices[0].message.content // "Keine AI-Antwort erhalten"' 2>/dev/null)
        
        if [ -n "$ai_content" ] && [ "$ai_content" != "null" ] && [ "$ai_content" != "Keine AI-Antwort erhalten" ]; then
            echo "$ai_content"
        else
            log "⚠️ AI-Hub Response invalid or empty"
            log "🔍 Full API Response: $ai_response"
            echo "AI-Review konnte nicht erstellt werden - ungültige Antwort vom Hub."
        fi
    else
        log "⚠️ AI-Review konnte nicht erstellt werden (curl exit: $curl_exit_code)"
        echo "AI-Review konnte nicht erstellt werden - Hub nicht erreichbar."
    fi
    
    # Cleanup
    rm -f "$temp_request_file" 2>/dev/null
}

# Set defaults for AI configuration
[ "$USE_AI" = "null" ] && USE_AI="false"
[ "$ADESSO_HUB_URL" = "null" ] && ADESSO_HUB_URL=""
[ "$ADESSO_API_KEY" = "null" ] && ADESSO_API_KEY=""
[ "$ADESSO_MODEL" = "null" ] && ADESSO_MODEL="gpt-oss-120b-sovereign"
[ "$ADESSO_MAX_TOKENS" = "null" ] && ADESSO_MAX_TOKENS="2000"
[ "$ADESSO_TEMPERATURE" = "null" ] && ADESSO_TEMPERATURE="0.1"

# Export AI configuration for use in functions
export USE_AI ADESSO_HUB_URL ADESSO_API_KEY ADESSO_MODEL ADESSO_MAX_TOKENS ADESSO_TEMPERATURE

if [ "$GIT_USERNAME" = "null" ] || [ "$GIT_PASSWORD" = "null" ]; then
    echo "❌ Error: Git credentials not found in $CONFIG_FILE"
    echo "Please ensure the JSON file contains valid 'git.username' and 'git.password' fields."
    exit 1
fi

if [ "$REPO_URL" = "null" ]; then
    echo "❌ Error: Repository URL not found in $CONFIG_FILE"
    echo "Please ensure the JSON file contains a valid 'repository.url' field."
    exit 1
fi

log "🚀 Starting automated code review for branch: $BRANCH_NAME"
log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Ensure results and checkout directories exist
mkdir -p "$RESULTS_DIR"
mkdir -p "$SCRIPT_DIR/checkout"

# Remove existing directory if it exists
if [ -d "$TARGET_DIR" ]; then
    log "🧹 Removing existing directory: $TARGET_DIR"
    rm -rf "$TARGET_DIR"
fi

# Create the target directory
mkdir -p "$TARGET_DIR"

log "📡 Cloning repository to: $TARGET_DIR"

# Construct URL with credentials
REPO_URL_WITH_CREDS=$(echo "$REPO_URL" | sed "s|https://|https://$GIT_USERNAME:$GIT_PASSWORD@|")

# Clone the repository (suppress credential warnings)
log "⬇️  Cloning repository (this may take a while for large repositories)..."

# Use a temporary file to capture git output and filter warnings
TEMP_OUTPUT=$(mktemp)
if git clone "$REPO_URL_WITH_CREDS" "$TARGET_DIR" 2>&1 | \
   grep -v "warning: current Git remote contains credentials" | \
   grep -v "remote: Azure Repos" | \
   tee "$TEMP_OUTPUT"; then
    # Check if clone was successful by checking if directory exists and has .git
    if [ -d "$TARGET_DIR/.git" ]; then
        log "✅ Repository cloned successfully"
    else
        echo "❌ Error: Clone appeared to succeed but repository directory is invalid."
        exit 1
    fi
else
    echo "❌ Error: Failed to clone repository."
    echo "Git output:"
    cat "$TEMP_OUTPUT" 2>/dev/null || true
    echo "Please check your credentials and network connection."
    rm -f "$TEMP_OUTPUT"
    exit 1
fi
rm -f "$TEMP_OUTPUT"

# Change to the repository directory
cd "$TARGET_DIR"

log "🔍 Fetching all branches..."
git fetch --all >/dev/null 2>&1

log "📂 Checking out branch: $BRANCH_NAME"

# First try to checkout the branch directly
if git checkout "$BRANCH_NAME" >/dev/null 2>&1; then
    log "✅ Successfully checked out branch: $BRANCH_NAME"
elif git checkout "origin/$BRANCH_NAME" >/dev/null 2>&1; then
    log "✅ Successfully checked out remote branch: origin/$BRANCH_NAME"
    # Create local tracking branch
    git checkout -b "$BRANCH_NAME" "origin/$BRANCH_NAME" >/dev/null 2>&1
else
    echo "❌ Error: Failed to checkout branch '$BRANCH_NAME'."
    echo ""
    echo "Available branches containing '$BRANCH_NAME':"
    git branch -a | grep -i "$BRANCH_NAME" || echo "No branches found containing '$BRANCH_NAME'"
    echo ""
    echo "All remote branches:"
    git branch -r | head -10
    if [ $(git branch -r | wc -l) -gt 10 ]; then
        echo "... and $(( $(git branch -r | wc -l) - 10 )) more branches"
    fi
    echo ""
    echo "Please check the exact branch name and try again."
    exit 1
fi

log "🔄 Fetching latest changes for branch: $BRANCH_NAME"
git pull origin "$BRANCH_NAME" >/dev/null 2>&1 || true

log "🎯 Finding branch point from develop..."

# Find the merge-base (common ancestor) between the current branch and develop
MERGE_BASE=$(git merge-base "$BRANCH_NAME" origin/develop 2>/dev/null || git merge-base "$BRANCH_NAME" develop 2>/dev/null)

if [ -z "$MERGE_BASE" ]; then
    echo "❌ Error: Could not find common ancestor between '$BRANCH_NAME' and 'develop' branch."
    echo "Please ensure both branches exist and have a common history."
    exit 1
fi

log "📍 Branch point found: $MERGE_BASE"

# Get the author of the last commit on the current branch
LAST_COMMIT_AUTHOR=$(git log -1 --format="%an" "$BRANCH_NAME")
LAST_COMMIT_EMAIL=$(git log -1 --format="%ae" "$BRANCH_NAME")
LAST_COMMIT_HASH=$(git log -1 --format="%H" "$BRANCH_NAME")
LAST_COMMIT_DATE=$(git log -1 --format="%ai" "$BRANCH_NAME")
LAST_COMMIT_MESSAGE=$(git log -1 --format="%s" "$BRANCH_NAME")

log "👤 Last commit author: $LAST_COMMIT_AUTHOR <$LAST_COMMIT_EMAIL>"

# Create only the consolidated review file (no separate files)
REVIEW_FILE="$RESULTS_DIR/${DATE_PREFIX}_complete-review-$BRANCH_NAME_NORMALIZED.md"

log "📝 Generating comprehensive code review..."

# Create temporary diff data and summary data (in memory only)
DIFF_DATA=$(git diff "$MERGE_BASE".."$BRANCH_NAME")
TEMP_DIFF_FILE=$(mktemp)
echo "$DIFF_DATA" > "$TEMP_DIFF_FILE"

TEMP_SUMMARY_FILE=$(mktemp)
{
    echo "=== Branch Analysis Summary ==="
    echo "Branch: $BRANCH_NAME"
    echo "Analysis Date: $(date)"
    echo "Repository: $REPO_URL"
    echo "Target Directory: $TARGET_DIR"
    echo ""
    echo "=== Branch Information ==="
    echo "Last Commit Author: $LAST_COMMIT_AUTHOR <$LAST_COMMIT_EMAIL>"
    echo "Last Commit Hash: $LAST_COMMIT_HASH"
    echo "Last Commit Date: $LAST_COMMIT_DATE"
    echo "Last Commit Message: $LAST_COMMIT_MESSAGE"
    echo ""
    echo "=== Branch Point Information ==="
    echo "Merge Base (Branch Point): $MERGE_BASE"
    echo "Merge Base Date: $(git log -1 --format="%ai" "$MERGE_BASE")"
    echo ""
    echo "=== Statistics ==="
    echo "Total Commits in Branch: $TOTAL_COMMITS"
    echo "Files Changed: $CHANGED_FILES"
    echo "Change Statistics: $STATS"
    echo ""
    echo "=== Changed Files ==="
    git diff --name-status "$MERGE_BASE".."$BRANCH_NAME"
    echo ""
    echo "=== Commit Log ==="
    git log --oneline "$MERGE_BASE".."$BRANCH_NAME"
} > "$TEMP_SUMMARY_FILE"

# Get statistics
TOTAL_COMMITS=$(git rev-list --count "$MERGE_BASE".."$BRANCH_NAME")
CHANGED_FILES=$(git diff --name-only "$MERGE_BASE".."$BRANCH_NAME" | wc -l)
STATS=$(git diff --stat "$MERGE_BASE".."$BRANCH_NAME" | tail -1)

# Create summary data in memory (not saved to separate file)
SUMMARY_DATA="=== Branch Analysis Summary ===
Branch: $BRANCH_NAME
Analysis Date: $(date)
Repository: $REPO_URL

=== Branch Information ===
Last Commit Author: $LAST_COMMIT_AUTHOR <$LAST_COMMIT_EMAIL>
Last Commit Hash: $LAST_COMMIT_HASH
Last Commit Date: $LAST_COMMIT_DATE
Last Commit Message: $LAST_COMMIT_MESSAGE

=== Branch Point Information ===
Merge Base (Branch Point): $MERGE_BASE
Merge Base Date: $(git log -1 --format="%ai" "$MERGE_BASE")

=== Statistics ===
Total Commits in Branch: $TOTAL_COMMITS
Files Changed: $CHANGED_FILES
Change Statistics: $STATS

=== Changed Files ===
$(git diff --name-status "$MERGE_BASE".."$BRANCH_NAME")

=== Commit Log ===
$(git log --oneline "$MERGE_BASE".."$BRANCH_NAME")"

log "🔍 Analyzing diff for comprehensive review..."

# Function to analyze diff content
analyze_diff() {
    local diff_file="$1"
    local added_lines=0
    local removed_lines=0
    local modified_files=0
    local added_files=0
    local deleted_files=0
    
    # Count lines and files
    while IFS= read -r line; do
        if [[ "$line" =~ ^diff\ --git ]]; then
            ((modified_files++))
        elif [[ "$line" =~ ^new\ file\ mode ]]; then
            ((added_files++))
        elif [[ "$line" =~ ^deleted\ file\ mode ]]; then
            ((deleted_files++))
        elif [[ "$line" =~ ^[+][^+] ]]; then
            ((added_lines++))
        elif [[ "$line" =~ ^[-][^-] ]]; then
            ((removed_lines++))
        fi
    done < "$diff_file"
    
    echo "$added_lines $removed_lines $modified_files $added_files $deleted_files"
}

# Get diff analysis
DIFF_ANALYSIS=($(analyze_diff "$TEMP_DIFF_FILE"))
ADDED_LINES=${DIFF_ANALYSIS[0]}
REMOVED_LINES=${DIFF_ANALYSIS[1]}
MODIFIED_FILES=${DIFF_ANALYSIS[2]}
ADDED_FILES=${DIFF_ANALYSIS[3]}
DELETED_FILES=${DIFF_ANALYSIS[4]}

# Function to get file extensions
get_file_extensions() {
    git diff --name-only "$MERGE_BASE".."$BRANCH_NAME" | while read -r file; do
        echo "${file##*.}"
    done | sort | uniq -c | sort -nr
}

# Function to check for specific file types
check_file_types() {
    local files=$(git diff --name-only "$MERGE_BASE".."$BRANCH_NAME")
    local has_tests=false
    local has_config=false
    local has_package=false
    
    while read -r file; do
        if [[ "$file" =~ (test|spec) ]]; then
            has_tests=true
        fi
        if [[ "$file" =~ (config|\.env) ]]; then
            has_config=true
        fi
        if [[ "$file" =~ package\.json ]]; then
            has_package=true
        fi
    done <<< "$files"
    
    echo "$has_tests $has_config $has_package"
}

# Get file type analysis
FILE_TYPE_ANALYSIS=($(check_file_types))
HAS_TESTS=${FILE_TYPE_ANALYSIS[0]}
HAS_CONFIG=${FILE_TYPE_ANALYSIS[1]}
HAS_PACKAGE=${FILE_TYPE_ANALYSIS[2]}

log "📋 Generating comprehensive code review: $REVIEW_FILE"

# Function to generate AI review using Adesso AI Hub (returns content instead of creating file)
generate_ai_review_content() {
    # Check if AI is enabled
    if [ "$USE_AI" != "true" ]; then
        log "🤖 AI reviews disabled in configuration, skipping AI review generation"
        return 0
    fi
    
    # Check if Adesso AI Hub is configured
    if [ -z "$ADESSO_HUB_URL" ] || [ -z "$ADESSO_API_KEY" ]; then
        log "⚠️ Adesso AI Hub not configured, skipping AI review generation"
        return 0
    fi
    
    log "🤖 Generating AI review using Adesso AI Hub..."
    
    # Create a comprehensive prompt for the AI Hub
    local prompt_content=""
    prompt_content+="Führe eine umfassende Code-Review der folgenden Änderungen durch:\n\n"
    prompt_content+="BRANCH: $BRANCH_NAME\n"
    prompt_content+="AUTOR: $LAST_COMMIT_AUTHOR\n"
    prompt_content+="COMMIT: $LAST_COMMIT_MESSAGE\n\n"
    prompt_content+="STATISTIKEN:\n"
    prompt_content+="- Geänderte Dateien: $MODIFIED_FILES\n"
    prompt_content+="- Hinzugefügte Zeilen: $ADDED_LINES\n"
    prompt_content+="- Entfernte Zeilen: $REMOVED_LINES\n"
    prompt_content+="- Netto-Änderung: $((ADDED_LINES - REMOVED_LINES)) Zeilen\n\n"
    prompt_content+="GEÄNDERTE DATEIEN:\n"
    prompt_content+="$(git diff --name-status "$MERGE_BASE".."$BRANCH_NAME" | head -10)\n\n"
    prompt_content+="CODE-ÄNDERUNGEN:\n"
    prompt_content+="$(head -800 "$diff_file")\n\n"
    prompt_content+="Analysiere dieses Code-Review mit Fokus auf:\n"
    prompt_content+="1. Code-Qualität und Best Practices\n"
    prompt_content+="2. Potentielle Bugs oder Sicherheitslücken\n"
    prompt_content+="3. Performance-Auswirkungen\n"
    prompt_content+="4. Wartbarkeit und Lesbarkeit\n"
    prompt_content+="5. Architektur- und Design-Entscheidungen\n"
    prompt_content+="6. Test-Abdeckung und -Qualität\n"
    prompt_content+="7. Dokumentationsangemessenheit\n"
    prompt_content+="8. Allgemeine Risikobewertung\n\n"
    prompt_content+="Gib spezifische Empfehlungen und eine Approval-Empfehlung (APPROVE/NEEDS_CHANGES/REJECT).\n"
    prompt_content+="Strukturiere deine Antwort im Markdown-Format auf Deutsch."
    
    # Create JSON payload for Adesso AI Hub
    local json_payload
    json_payload=$(jq -n \
        --arg model "$ADESSO_MODEL" \
        --arg content "$prompt_content" \
        --argjson max_tokens "$ADESSO_MAX_TOKENS" \
        --argjson temperature "$ADESSO_TEMPERATURE" \
        '{
            "model": $model,
            "messages": [
                {
                    "role": "system",
                    "content": "Du bist ein erfahrener Code-Reviewer mit tiefem Wissen über Software-Engineering Best Practices, Sicherheitslücken, Performance-Optimierung und wartbare Code-Architektur. Gib detailliertes, umsetzbares Code-Review-Feedback mit spezifischen Empfehlungen auf Deutsch."
                },
                {
                    "role": "user",
                    "content": $content
                }
            ],
            "max_tokens": $max_tokens,
            "temperature": $temperature
        }')
    
    # Make API call to Adesso AI Hub
    local response_file=$(mktemp)
    local http_status
    
    http_status=$(curl -s -w "%{http_code}" -X POST "$ADESSO_HUB_URL" \
        -H "Authorization: Bearer $ADESSO_API_KEY" \
        -H "Content-Type: application/json" \
        -d "$json_payload" \
        -o "$response_file")
    
    # Check if API call was successful
    if [ "$http_status" = "200" ]; then
        # Check if response contains valid AI content
        local ai_content
        ai_content=$(jq -r '.choices[0].message.content' "$response_file" 2>/dev/null)
        
        if [ "$ai_content" != "null" ] && [ -n "$ai_content" ]; then
            # Generate the AI review file with the response
            {
                echo "# AI Code Review (Adesso AI Hub)"
                echo ""
                echo "**Branch:** $BRANCH_NAME"
                echo "**Autor:** $LAST_COMMIT_AUTHOR"
                echo "**Generiert:** $(date '+%Y-%m-%d %H:%M:%S')"
                echo "**KI-Modell:** $ADESSO_MODEL"
                echo "**AI Hub:** Adesso AI Hub"
                echo ""
                echo "---"
                echo ""
                echo "$ai_content"
                echo ""
                echo "---"
                echo ""
                echo "**Technische Details:**"
                echo "- Dateien geändert: $MODIFIED_FILES"
                echo "- Zeilen hinzugefügt: $ADDED_LINES"
                echo "- Zeilen entfernt: $REMOVED_LINES"
                echo "- Netto-Änderung: $((ADDED_LINES - REMOVED_LINES)) Zeilen"
                echo "- Commits: $TOTAL_COMMITS"
                echo ""
                echo "*Generiert durch Adesso AI Hub - $(date '+%Y-%m-%d %H:%M:%S')*"
            } > "$ai_review_file"
            
            log "✅ AI-Review erfolgreich mit Adesso AI Hub generiert"
        else
            log "⚠️ Adesso AI Hub Response enthält keinen gültigen Content"
            rm -f "$response_file"
            return 1
        fi
    else
        log "⚠️ Adesso AI Hub nicht erreichbar (HTTP $http_status), AI-Review wird nicht erstellt"
        rm -f "$response_file"
        return 1
    fi
    
    # Cleanup temp files
    rm -f "$response_file"
    return 0
}

# Function to generate Management Summary using Adesso AI Hub
generate_management_summary() {
    local ai_content="$1"
    
    log "🤖 Generiere Management Summary..."
    
    # Create management summary prompt
    local summary_prompt=""
    summary_prompt+="Basierend auf dem folgenden Code-Review erstelle ein kurzes Management Summary in Prosa-Form:\n\n"
    summary_prompt+="BRANCH: $BRANCH_NAME\n"
    summary_prompt+="AUTOR: $LAST_COMMIT_AUTHOR\n"
    summary_prompt+="ÄNDERUNGEN: $MODIFIED_FILES Dateien, +$ADDED_LINES/-$REMOVED_LINES Zeilen\n\n"
    summary_prompt+="CODE REVIEW:\n$ai_content\n\n"
    summary_prompt+="Erstelle ein Management Summary mit:\n"
    summary_prompt+="1. Was wurde geändert (1-2 Sätze)\n"
    summary_prompt+="2. Qualitätsbewertung (Gut/Mittel/Schlecht mit Begründung)\n"
    summary_prompt+="3. Risikobewertung (Niedrig/Mittel/Hoch mit Begründung)\n"
    summary_prompt+="4. Empfehlung (Deployment empfohlen/mit Vorsicht/nicht empfohlen)\n"
    summary_prompt+="5. Nächste Schritte (wenn nötig)\n\n"
    summary_prompt+="Halte es prägnant und geschäftsorientiert. Verwende deutsche Sprache."
    
    # Create JSON payload for management summary
    local json_payload
    json_payload=$(jq -n \
        --arg model "$ADESSO_MODEL" \
        --arg content "$summary_prompt" \
        --argjson max_tokens "500" \
        --argjson temperature "0.1" \
        '{
            "model": $model,
            "messages": [
                {
                    "role": "system",
                    "content": "Du bist ein erfahrener Engineering Manager. Erstelle prägnante Management Summaries für Code Reviews, die für Führungskräfte verständlich sind."
                },
                {
                    "role": "user",
                    "content": $content
                }
            ],
            "max_tokens": $max_tokens,
            "temperature": $temperature
        }')
    
    # Make API call for management summary
    local response_file=$(mktemp)
    local http_status
    
    http_status=$(curl -s -w "%{http_code}" -X POST "$ADESSO_HUB_URL" \
        -H "Authorization: Bearer $ADESSO_API_KEY" \
        -H "Content-Type: application/json" \
        -d "$json_payload" \
        -o "$response_file")
    
    local management_summary=""
    if [ "$http_status" = "200" ]; then
        management_summary=$(jq -r '.choices[0].message.content' "$response_file" 2>/dev/null)
        if [ "$management_summary" = "null" ] || [ -z "$management_summary" ]; then
            management_summary="Management Summary konnte nicht generiert werden."
        fi
    else
        management_summary="Management Summary nicht verfügbar (AI Hub nicht erreichbar)."
    fi
    
    rm -f "$response_file"
    echo "$management_summary"
}

# Function to create consolidated review file
create_consolidated_review() {
    local diff_file="$1"
    local summary_file="$2" 
    local review_file="$3"
    local ai_review_content="$4"
    local consolidated_file="${RESULTS_DIR}/${DATE_PREFIX}_complete-review-$BRANCH_NAME_NORMALIZED.md"
    
    log "📋 Erstelle konsolidierte Review-Datei..."
    
    # Generate management summary if AI content is available
    local management_summary=""
    if [ -n "$ai_review_content" ] && [ "$ai_review_content" != "AI-Review konnte nicht erstellt werden"* ]; then
        management_summary=$(generate_management_summary "$ai_review_content")
    fi
    
    # Start building consolidated file
    {
        echo "# Vollständige Code-Review: $BRANCH_NAME"
        echo ""
        echo "**Autor:** $LAST_COMMIT_AUTHOR"  
        echo "**Generiert:** $(date '+%Y-%m-%d %H:%M:%S')"
        echo "**Branch:** $BRANCH_NAME"
        echo ""
        
        # Table of Contents
        echo "## 📋 Inhaltsverzeichnis"
        echo ""
        echo "1. [Management Summary](#management-summary)"
        echo "2. [Übersichtstabelle](#übersichtstabelle)" 
        echo "3. [AI-Review](#ai-review)"
        echo "4. [Technische Details](#technische-details)"
        echo "5. [Code-Änderungen (Diff)](#code-änderungen-diff)"
        echo ""
        
        # Management Summary
        echo "## Management Summary"
        echo ""
        if [ -n "$management_summary" ] && [ "$management_summary" != "Management Summary konnte nicht generiert werden." ]; then
            echo "$management_summary"
        else
            echo "**Was wurde geändert:** $MODIFIED_FILES Dateien mit $((ADDED_LINES - REMOVED_LINES)) Netto-Zeilen-Änderungen"
            echo ""
            total_changes=$((ADDED_LINES + REMOVED_LINES))
            if [ $total_changes -lt 50 ]; then
                echo "**Qualitätsbewertung:** Kleine Änderung mit geringem Risiko"
                echo "**Empfehlung:** Deployment nach Standard-Review empfohlen"
            elif [ $total_changes -lt 200 ]; then
                echo "**Qualitätsbewertung:** Mittlere Änderung, sorgfältige Prüfung empfohlen"
                echo "**Empfehlung:** Deployment nach ausführlichem Testing"
            else
                echo "**Qualitätsbewertung:** Große Änderung, umfassende Prüfung erforderlich"
                echo "**Empfehlung:** Stufenweises Deployment mit Monitoring"
            fi
        fi
        echo ""
        
        # Overview Table
        echo "## Übersichtstabelle"
        echo ""
        echo "| Metrik | Wert |"
        echo "|--------|------|"
        echo "| **Branch** | $BRANCH_NAME |"
        echo "| **Autor** | $LAST_COMMIT_AUTHOR |"
        echo "| **Dateien geändert** | $MODIFIED_FILES |"
        echo "| **Zeilen hinzugefügt** | $ADDED_LINES |"
        echo "| **Zeilen entfernt** | $REMOVED_LINES |" 
        echo "| **Netto-Änderung** | $((ADDED_LINES - REMOVED_LINES)) Zeilen |"
        echo "| **Commits** | $TOTAL_COMMITS |"
        echo "| **Letzter Commit** | $LAST_COMMIT_MESSAGE |"
        if [ "$HAS_TESTS" = "true" ]; then
            echo "| **Tests** | ✅ Enthalten |"
        else
            echo "| **Tests** | ⚠️ Nicht erkannt |"
        fi
        if [ "$HAS_CONFIG" = "true" ]; then
            echo "| **Konfiguration** | ⚠️ Geändert |"
        else
            echo "| **Konfiguration** | ✅ Unverändert |"
        fi
        echo ""
        
        # AI Review Section
        echo "## AI-Review"
        echo ""
        if [ -n "$ai_review_content" ] && [ "$ai_review_content" != "AI-Review konnte nicht erstellt werden"* ]; then
            echo "$ai_review_content"
        else
            echo "**AI-Review Status:** Nicht verfügbar"
            echo ""
            if [ "$USE_AI" != "true" ]; then
                echo "- AI-Reviews sind in der Konfiguration deaktiviert"
            elif [ -z "$ADESSO_HUB_URL" ] || [ -z "$ADESSO_API_KEY" ]; then
                echo "- Adesso AI Hub ist nicht konfiguriert"
            else
                echo "- AI-Hub war während der Generierung nicht erreichbar"
            fi
        fi
        echo ""
        
        # Technical Details (only if summary file exists and has unique content)
        if [ -f "$summary_file" ]; then
            echo "## Technische Details"
            echo ""
            echo "### Branch-Informationen"
            echo '```'
            head -20 "$summary_file"
            echo '```'
            echo ""
        fi
        
        # Diff Section
        echo "## Code-Änderungen (Diff)"
        echo ""
        echo "### Geänderte Dateien"
        echo ""
        git diff --name-status "$MERGE_BASE".."$BRANCH_NAME" | while read -r status file; do
            case "$status" in
                "M") echo "- **Geändert:** \`$file\`" ;;
                "A") echo "- **Hinzugefügt:** \`$file\`" ;;
                "D") echo "- **Gelöscht:** \`$file\`" ;; 
                "R"*) echo "- **Umbenannt:** \`$file\`" ;;
                *) echo "- **$status:** \`$file\`" ;;
            esac
        done
        echo ""
        
        echo "### Vollständiger Diff"
        echo ""
        echo "<details>"
        echo "<summary>Klicken zum Anzeigen des vollständigen Diffs</summary>"
        echo ""
        echo '```diff'
        if [ -f "$diff_file" ]; then
            cat "$diff_file"
        else
            echo "Diff-Datei nicht verfügbar."
        fi
        echo '```'
        echo ""
        echo "</details>"
        echo ""
        
        echo "---"
        echo ""
        echo "*Vollständige Review generiert am $(date '+%Y-%m-%d %H:%M:%S')*"
        if [ -n "$ai_review_content" ] && [ "$ai_review_content" != "AI-Review konnte nicht erstellt werden"* ]; then
            echo "*AI-Analyse durch Adesso AI Hub*"
        fi
        
    } > "$consolidated_file"
    
    echo "$consolidated_file"
}

# Function to create enhanced automated review when AI is not available
create_enhanced_automated_review() {
    local ai_review_file="$1"
    
    {
        echo "# GitHub Copilot Review Request"
        echo ""
        echo "**Branch:** $BRANCH_NAME"
        echo "**Author:** $LAST_COMMIT_AUTHOR" 
        echo "**Generated:** $(date '+%Y-%m-%d %H:%M:%S')"
        echo ""
        echo "## ⚡ Quick GitHub Copilot Review"
        echo ""
        echo "### � To get an AI review from GitHub Copilot:"
        echo ""
        echo "1. **Open this diff file in VS Code:**"
        echo "   \`${DATE_PREFIX}_branch-diff-$BRANCH_NAME_NORMALIZED.patch\`"
        echo ""
        echo "2. **Open Copilot Chat (Ctrl+Shift+I / Cmd+Shift+I)**"
        echo ""
        echo "3. **Copy this prompt:**"
        echo ""
        echo '```'
        echo "Please perform a comprehensive code review of this diff."
        echo ""
        echo "Branch: $BRANCH_NAME"
        echo "Author: $LAST_COMMIT_AUTHOR"
        echo "Files changed: $MODIFIED_FILES"
        echo "Lines: +$ADDED_LINES/-$REMOVED_LINES"
        echo ""
        echo "Focus on:"
        echo "- Code quality and best practices"
        echo "- Security vulnerabilities"
        echo "- Performance implications"  
        echo "- Maintainability issues"
        echo "- Architecture decisions"
        echo "- Test coverage"
        echo ""
        echo "Provide specific recommendations and overall approval (APPROVE/NEEDS_CHANGES)."
        echo '```'
        echo ""
        echo "## 🤖 Alternative: Use GitHub Copilot CLI"
        echo ""
        echo "If you have GitHub Copilot CLI installed:"
        echo ""
        echo '```bash'
        echo "gh copilot explain < ${DATE_PREFIX}_branch-diff-$BRANCH_NAME_NORMALIZED.patch"
        echo '```'
        echo ""
        echo "## 📊 Automated Pre-Analysis"
        echo ""
        
        total_changes=$((ADDED_LINES + REMOVED_LINES))
        echo "**Change Complexity:** "
        if [ $total_changes -gt 500 ]; then
            echo "🔴 **HIGH** ($total_changes lines) - Significant change requiring thorough review"
        elif [ $total_changes -gt 100 ]; then
            echo "⚠️ **MEDIUM** ($total_changes lines) - Moderate change, standard review needed"
        else
            echo "✅ **LOW** ($total_changes lines) - Small change, quick review sufficient"
        fi
        echo ""
        
        echo "**Key Indicators:**"
        if [ "$HAS_TESTS" = "true" ]; then
            echo "- ✅ **Tests included** - Good practice"
        else
            echo "- ⚠️ **No tests detected** - Consider adding tests"
        fi
        
        if [ "$HAS_CONFIG" = "true" ]; then
            echo "- ⚠️ **Config changes** - Review security implications"
        fi
        
        if [ "$HAS_PACKAGE" = "true" ]; then
            echo "- 📦 **Dependencies changed** - Verify compatibility"
        fi
        echo ""
        
        echo "**File Impact:**"
        echo "- Modified files: $MODIFIED_FILES"
        echo "- Net change: $((ADDED_LINES - REMOVED_LINES)) lines"
        echo "- Commits: $TOTAL_COMMITS"
        echo ""
        
        echo "## 🚀 Next Steps"
        echo ""
        echo "1. **Get AI Review**: Use one of the methods above for intelligent analysis"
        echo "2. **Manual Review**: Check the generated review file for detailed breakdown"  
        echo "3. **Test**: Ensure changes work as expected"
        echo "4. **Deploy**: Follow standard deployment process"
        echo ""
        echo "---"
        echo "*This file will be automatically replaced with AI results when GitHub Copilot CLI is available*"
        
    } > "$ai_review_file"
}

# Generate AI review if available, then create the final consolidated review file directly
AI_REVIEW_CONTENT=""

# Call AI review function with correct parameters
AI_REVIEW_RESULT=$(generate_ai_review "$BRANCH_NAME" "$LAST_COMMIT_AUTHOR" "$LAST_COMMIT_MESSAGE" "$(cat $TEMP_DIFF_FILE)")

if [ -n "$AI_REVIEW_RESULT" ] && [ "$AI_REVIEW_RESULT" != "AI-Review konnte nicht erstellt werden"* ]; then
    log "✅ AI-Review erfolgreich erstellt"
    AI_REVIEW_CONTENT="$AI_REVIEW_RESULT"
else
    log "⚠️ AI-Review konnte nicht erstellt werden (Hub nicht erreichbar)"
    AI_REVIEW_CONTENT="AI-Review konnte nicht erstellt werden - Hub nicht erreichbar."
fi

# Create the final consolidated review file (this is now the ONLY file created)
CONSOLIDATED_FILE=$(create_consolidated_review "$TEMP_DIFF_FILE" "$TEMP_SUMMARY_FILE" "$REVIEW_FILE" "$AI_REVIEW_CONTENT")
log "📋 Einzige Review-Datei erstellt: $(basename "$CONSOLIDATED_FILE")"

# Clean up temporary files
rm -f "$TEMP_DIFF_FILE" "$TEMP_SUMMARY_FILE" "$AI_REVIEW_FILE"

# Cleanup: Change back to script directory and remove cloned repository
cd "$SCRIPT_DIR"
log "🧹 Cleaning up: Removing cloned repository directory"
rm -rf "$TARGET_DIR"

# Clean up any other repository directories that might exist in checkout directory
find "$SCRIPT_DIR/checkout" -type d -name "ts-mono-repo-*" -exec rm -rf {} + 2>/dev/null || true

log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log "✅ CODE REVIEW COMPLETED SUCCESSFULLY"
log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
log "📋 **Review Summary for $BRANCH_NAME**"
log "👤 Author: $LAST_COMMIT_AUTHOR"
log "📁 Files Changed: $MODIFIED_FILES"
log "➕ Lines Added: $ADDED_LINES"
log "➖ Lines Removed: $REMOVED_LINES"
log "💾 Net Change: $((ADDED_LINES - REMOVED_LINES)) lines"
echo ""
log "📄 **Generated File:** $(basename "$CONSOLIDATED_FILE")"
log "📁 **Location:** $(basename $RESULTS_DIR)/"
echo ""

# Display key parts of the review in console
log "📝 **Key Review Points:**"
echo ""

# Show change size assessment
total_changes=$((ADDED_LINES + REMOVED_LINES))
if [ $total_changes -lt 50 ]; then
    log "✅ **Small Change** - Low risk, easy to review"
elif [ $total_changes -lt 200 ]; then
    log "⚠️ **Medium Change** - Moderate complexity, careful review needed"
else
    log "🔴 **Large Change** - High complexity, thorough review required"
fi

# Show recommendations
if [ "$HAS_TESTS" = "true" ]; then
    log "✅ Tests were added or modified - Good practice!"
fi

if [ "$HAS_PACKAGE" = "true" ]; then
    log "📦 Dependencies changed - Verify compatibility"
fi

if [ "$HAS_CONFIG" = "true" ]; then
    log "⚙️ Configuration files changed - Review for security"
fi

echo ""
log "🎉 Review completed! Check results in: $(basename $RESULTS_DIR)/"