#!/bin/bash

RC_FILE="${HOME}/.zshrc"
# 설치 스크립트 실행 위치에 관계없이 절대경로를 동적으로 찾습니다. (다른 서버에서 clone 시 유용)
SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]:-$0}" )" &> /dev/null && pwd )"
TRANSLATE_PY_PATH="${SCRIPT_DIR}/translate.py"

echo "---------------------------------------------------"
echo " 'translate' 명령어 등록 및 ZSH 설정을 시작합니다."
echo " 동적 경로 매핑: $TRANSLATE_PY_PATH"
echo "---------------------------------------------------"

# 1. ~/.zshrc 파일 안전하게 백업
BACKUP_FILE="${RC_FILE}.backup_$(date +%Y%m%d_%H%M%S)"
cp "$RC_FILE" "$BACKUP_FILE"
echo "✅ 기존 환경설정 백업 완료: $BACKUP_FILE"

# 2. 에러의 원인이 되는 기존 alias 또는 예전 버전을 삭제
sed -i '' '/^# ====== AI Translation CLI Tool ======/,/^# =====================================/d' "$RC_FILE" 2>/dev/null || true
sed -i '' '/^alias translate=/s/^/# /g' "$RC_FILE" 2>/dev/null || true
sed -i '' '/^translate() {/d' "$RC_FILE" 2>/dev/null || true

# 3. 파이프(|), 인자 전달, 클립보드(-c) 모두 가능한 고급 함수 추가
# TRANSLATE_PY_PATH 환경변수가 ZSH에 온전히 전달되도록 EOF 블록을 분리해서 안전하게 주입합니다.
cat << EOF >> "$RC_FILE"
# ====== AI Translation CLI Tool ======
_translate_impl() {
    local TRANSLATE_PY_PATH="${TRANSLATE_PY_PATH}"
EOF

cat << 'EOF' >> "$RC_FILE"
    local text=""
    local use_clipboard=0
    
    # 전달받은 인자들 중에서 --clipboard 또는 -c 옵션만 분리해냅니다.
    for arg in "$@"; do
        if [[ "$arg" == "--clipboard" || "$arg" == "-c" ]]; then
            use_clipboard=1
        else
            text="$text $arg"
        fi
    done
    
    # 텍스트 앞뒤 공백 제거
    text=$(echo "$text" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
    
    # 파일 경로로 간주할 수 있는지 확인
    local is_file_mode=0
    
    # clipboard 옵션이 없고, 첫번째 인자가 실제 존재하는 파일이면 파일 번역 모드로 동작
    if [ "$use_clipboard" -eq 0 ] && [ $# -gt 0 ] && [ -f "$1" ]; then
        is_file_mode=1
    # --dir 옵션을 사용한 경우도 파일 모드로 동작
    elif [[ " $@ " =~ " --dir " ]]; then
        is_file_mode=1
    fi

    if [ "$is_file_mode" -eq 1 ]; then
        # 원본 인자를 그대로 python 스크립트에 전달
        python3 "${TRANSLATE_PY_PATH}" "$@"
    elif [ -z "$text" ]; then
        # 1. 터미널 텍스트 인자가 없는 경우
        if [ ! -t 0 ]; then
            # 파이프 입력으로 들어온 경우 (예: cat list.txt | translate -c)
            if [ "$use_clipboard" -eq 1 ]; then
                if command -v pbcopy >/dev/null 2>&1; then
                    python3 "${TRANSLATE_PY_PATH}" | pbcopy
                    echo "✅ 번역 결과가 클립보드에 복사되었습니다."
                elif command -v xclip >/dev/null 2>&1; then
                    python3 "${TRANSLATE_PY_PATH}" | xclip -selection clipboard
                    echo "✅ 번역 결과가 클립보드에 복사되었습니다."
                else
                    python3 "${TRANSLATE_PY_PATH}"
                fi
            else
                python3 "${TRANSLATE_PY_PATH}"
            fi
        else
            # 인자나 파이프가 비어있고 그냥 쳤을 때 (예: translate -c 만 친 경우)
            if [ "$use_clipboard" -eq 1 ]; then
                python3 "${TRANSLATE_PY_PATH}" --clipboard
            else
                python3 "${TRANSLATE_PY_PATH}"
            fi
        fi
    else
        # 2. 텍스트가 직접 주어진 경우
        if [ "$use_clipboard" -eq 1 ]; then
            if command -v pbcopy >/dev/null 2>&1; then
                echo "$text" | python3 "${TRANSLATE_PY_PATH}" | pbcopy
                echo "✅ 번역 결과가 클립보드에 복사되었습니다."
            elif command -v xclip >/dev/null 2>&1; then
                echo "$text" | python3 "${TRANSLATE_PY_PATH}" | xclip -selection clipboard
                echo "✅ 번역 결과가 클립보드에 복사되었습니다."
            else
                echo "$text" | python3 "${TRANSLATE_PY_PATH}"
                echo "⚠️ 클립보드 복사 도구(pbcopy, xclip)를 찾을 수 없습니다."
            fi
        else
            echo "$text" | python3 "${TRANSLATE_PY_PATH}"
        fi
    fi
}
alias translate='noglob _translate_impl'
# =====================================
EOF

echo ""
echo "✅ '.zshrc' 파일에 클립보드 지원 함수가 주입되었습니다."
# 이제 translate는 alias로 동작하므로 unalias를 호출하면 안 됩니다.

echo "---------------------------------------------------"
echo "🎉 이제 모든 준비가 끝났습니다! 아래 명령어를 복사해서 실행하면 즉시 적용됩니다:"
echo ""
echo "    source ~/.zshrc"
echo ""
echo "💡 추가된 테스트 예시:"
echo "    translate 안녕하세요 -c              # 번역하고 클립보드 복사"
echo "    translate --clipboard                # 클립보드에 있는 한국어를 번역해서 다시 클립보드에 복사"
echo "---------------------------------------------------"
