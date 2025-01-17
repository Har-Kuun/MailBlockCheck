#!/bin/bash

declare -A domains=(
    ["Gmail"]="gmail.com"
    ["Outlook"]="outlook.com"
    ["Yahoo Mail"]="yahoo.com"
    ["Apple iCloud"]="icloud.com"
    ["Inbox.eu"]="inbox.eu"
    ["Free.fr"]="free.fr"
    ["Mail.ru"]="mail.ru"
    ["QQ Mail"]="qq.com"
    ["GMX Mail"]="gmx.com"
    ["Mail.com"]="mail.com"
    ["163 Email"]="163.com"
    ["Sohu Email"]="sohu.com"
    ["Sina Email"]="sina.com"
    ["MXRoute"]="mxroute.com"
    ["FastMail"]="fastmail.com"
    ["Namecrane"]="namecrane.com"
    ["XYAMail"]="xyamail.com"
    ["ZohoMail"]="zoho.com"
    ["ProtonMail"]="proton.me"
)

declare -A results

function check_dependencies() {
    echo 
    echo '*******************************************************************'
    echo '*       Mail-Server Blocklist Check                               *'
    echo '*       Version 0.0.1                                             *'
    echo '*       Author: shc (Har-Kuun) https://qing.su                    *'
    echo '*       https://github.com/Har-Kuun/MailBlockCheck                *'
    echo '*       Thank you for using this script.  E-mail: hi@qing.su      *'
    echo '*******************************************************************'
    echo 
    echo "-------------------------------------------------------"
    echo ""
    echo "Checking dependencies..."
    missing_dependencies=()

    if ! command -v dig &> /dev/null; then
        missing_dependencies+=("dig")
    fi

    if ! command -v nc &> /dev/null; then
        missing_dependencies+=("nc")
    fi

    if [ ${#missing_dependencies[@]} -ne 0 ]; then
        echo "Missing dependencies: ${missing_dependencies[*]}"
        echo "You can try following commands to install the missing dependencies:"
        echo "-------------------------------------------------------"
        echo "- For Debian/Ubuntu: sudo apt-get install dnsutils netcat-openbsd"
        echo "- For CentOS/AlmaLinux: sudo yum install bind-utils nmap-ncat"
        echo "- For SUSE: sudo zypper install bind-utils netcat"
        echo "- For Fedora: sudo dnf install bind-utils nmap-ncat"
        echo "-------------------------------------------------------"
        exit 1
    fi

    echo "All dependencies are installed."
    echo ""
    echo "-------------------------------------------------------"
}

function check_port_25() {
    echo ""
    echo "Checking if outbound port 25 is open..."
    timeout 10 nc -z -w 10 smtp.aol.com 25 &> /dev/null

    if [ $? -ne 0 ]; then
        echo "Outbound port 25 is blocked.\n\nPlease configure your firewall or contact your server provider to unblock it."
        echo .
        exit 1
    fi

    echo "Outbound port 25 is open."
    echo ""
    echo "-------------------------------------------------------"
}


function test_smtp() {
    local service_name=$1
    local domain=$2
    echo "Testing SMTP for $service_name..."
    
    mx_server=$(dig +short MX "$domain" | sort -n | head -1 | awk '{print $2}')
    
    if [ -z "$mx_server" ]; then
        echo "No MX record found for $domain"
        echo "----------------------------------------"
        results[$service_name]="Error: No MX record"
        return
    fi
    
    echo "MX Server: $mx_server"
    
    if [[ $domain == "fastmail.com" ]] || [[  $domain == "namecrane.com"  ]]; then
        response=$(timeout 12 timeout --signal=SIGINT 5 nc -w 5 "${mx_server%?}" 25)
    else
        response=$(timeout 12 echo -e 'QUIT\r\n' | nc -w 12 "${mx_server%?}" 25 2>&1)
    fi

    if [ $? -eq 124 ] || [ $? -eq 125 ] || [ $? -eq 126 ] || [ $? -eq 127 ]; then
        results[$service_name]="Timeout"
    else
        status_code=$(echo "$response" | head -n1 | grep -o "^[0-9]\{3\}")
        
        if [ "$status_code" == "220" ]; then
            results[$service_name]="220 OK"
        elif [ -n "$status_code" ]; then
            results[$service_name]="Error $status_code"
        else
            results[$service_name]="Error: No response"
        fi
    fi

    if [[ $domain == "fastmail.com" ]] || [[  $domain == "namecrane.com"  ]]; then
        status_code=$(echo "$response" | head -n1 | grep -o "^[0-9]\{3\}")
        
        if [ "$status_code" == "220" ]; then
            results[$service_name]="220 OK"
        elif [ -n "$status_code" ]; then
            results[$service_name]="Error $status_code"
        else
            results[$service_name]="Error: No response"
        fi
    fi
    
    echo "$response"
    echo "----------------------------------------"
}

function print_summary() {
    echo ""
    echo "SMTP Blocklist Summary"
    echo "----------------------------------------"
    printf "%-20s | %-15s\n" "Service" "Status"
    echo "----------------------------------------"
    
    readarray -t results_services < <(printf '%s\n' "${!results[@]}")
    
    for service in "${results_services[@]}"; do
        printf "%-20s | %-15s\n" "$service" "${results[$service]}"
    done
    echo "----------------------------------------"
}


function main() {
    check_dependencies
    check_port_25
    print_summary

    for service_name in "${!domains[@]}"; do
        test_smtp "$service_name" "${domains[$service_name]}"
        echo ""
    done
}

main
exit 0

