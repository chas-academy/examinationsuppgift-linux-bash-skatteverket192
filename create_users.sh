#!/bin/bash
# Script för att skapa användare med hemkataloger, standardmappar och välkomstfil
# Endast root (superuser) kan köra detta script

# Kontrollera att scriptet körs som root
# id -u returnerar 0 om användaren är root
if [ "$(id -u)" != 0 ]; then
    echo "Detta skript måste köras som root (sudo su)"
    exit 1
fi

# Kontrollera att minst en användare skickats in som argument
# $# innehåller antalet argument som skickats till scriptet
if [[ $# -lt 1 ]]; then
    echo "Användning: $0 användare1 användare2 ..."
    exit 1
fi

# Skapa användare och hemkataloger med standardmappar
for USERNAME in "$@"; do
    echo "Hanterar användare: $USERNAME"

    # Kontrollera om användaren redan finns i systemet
    # id returnerar felkod om användaren inte finns
    if id "$USERNAME" &>/dev/null; then
        echo "Användaren $USERNAME finns redan. Hoppar över."
        continue
    fi

    # Skapa användaren
    # -m skapar hemkatalog
    # -s /bin/bash sätter standard skal till bash
    useradd -m -s /bin/bash "$USERNAME"

    # Spara hemkatalogens sökväg
    USER_HOME="/home/$USERNAME"

    # Skapa standardmappar inuti hemkatalogen
    mkdir -p "$USER_HOME/Documents" "$USER_HOME/Downloads" "$USER_HOME/Work"


    # Sätt rätt ägare på hemkatalogen och dess innehåll
    chown -R "$USERNAME:$USERNAME" "$USER_HOME"

    # Sätt strikta rättigheter på mapparna (endast ägaren kan läsa/skriva/utföra)
    chmod 700 "$USER_HOME/Documents" "$USER_HOME/Downloads" "$USER_HOME/Work"

    echo "Användare $USERNAME skapad korrekt."
done

# Steg 2: Skapa welcome.txt med välkomstmeddelande och lista över andra användare
for USERNAME in "$@"; do
    USER_HOME="/home/$USERNAME"
    WELCOME_FILE="$USER_HOME/welcome.txt"

    {
        # Skriv välkomstmeddelande
        echo "Välkommen $USERNAME"

        # Skriv rubrik för lista med andra användare
        echo "Befintliga användare på systemet:"

        # Lista alla systemanvändare med UID >= 1000 (vanliga användare)
        # Filtrera bort den aktuella användaren
        awk -F: -v user="$USERNAME" '$3 >= 1000 && $1 != user { print $1 }' /etc/passwd
    } > "$WELCOME_FILE"

    # Sätt ägare och rättigheter på welcome.txt
    # Endast ägaren kan läsa och skriva
    chown "$USERNAME:$USERNAME" "$WELCOME_FILE"
    chmod 600 "$WELCOME_FILE"
done
