echo "Select the options you want to run:"
echo "1. Install Homebrew, Casks and Formulas"
echo "2. Setup Shell"
echo "3. Setup Node.js"
echo "4. Setup VSCode"

read -p "Enter your choices separated by spaces (e.g., 1 2 3): " choices

IFS=' ' read -r -a choices_array <<< "$choices"

for choice in "${choices_array[@]}"; do
    case $choice in
        1)
            echo "𝕀𝕟𝕤𝕥𝕒𝕝𝕝 𝕙𝕠𝕞𝕖𝕓𝕣𝕖𝕨\n"
            sh ./homebrew/setup.sh
            ;;
        2)
            echo "𝕊𝕙𝕖𝕝𝕝 𝕤𝕖𝕥𝕦𝕡 𝕒𝕟𝕕 𝕔𝕠𝕟𝕗𝕚𝕘𝕦𝕣𝕒𝕥𝕚𝕠𝕟\n"
            sh ./shell/setup.sh
            ;;
        3)
            echo "𝕊𝕖𝕥𝕦𝕡 ℕ𝕠𝕕𝕖.𝕛𝕤\n"
            sh ./node/setup.sh
            ;;
        4)
            echo "𝕊𝕖𝕥𝕦𝕡 𝕍𝕊ℂ𝕠𝕕𝕖, 𝕖𝕩𝕥𝕖𝕟𝕤𝕚𝕠𝕟𝕤 𝕒𝕟𝕕 𝕤𝕖𝕥𝕥𝕚𝕟𝕘𝕤\n"
            sh ./vscode/setup.sh
            ;;
        *)
            echo "Invalid choice: $choice"
            ;;
    esac
done