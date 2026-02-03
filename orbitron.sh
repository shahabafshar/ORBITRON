#!/bin/bash

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# ASCII Art
ORBITRON_ART="
${CYAN}
    ██████╗ ██████╗ ██████╗ ██╗████████╗██████╗  ██████╗ ███╗   ██╗
   ██╔═══██╗██╔══██╗██╔══██╗██║╚══██╔══╝██╔══██╗██╔═══██╗████╗  ██║
   ██║   ██║██████╔╝██████╔╝██║   ██║   ██████╔╝██║   ██║██╔██╗ ██║
   ██║   ██║██╔══██╗██╔══██╗██║   ██║   ██╔══██╗██║   ██║██║╚██╗██║
   ╚██████╔╝██║  ██║██████╔╝██║   ██║   ██║  ██║╚██████╔╝██║ ╚████║
    ╚═════╝ ╚═╝  ╚═╝ ╚════╝ ╚═╝   ╚═╝   ╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═══╝
${NC}"

# Function to check system requirements
check_requirements() {
    echo -e "\n${CYAN}Checking system requirements...${NC}"
    
    # Check for required commands
    local required_commands=("ssh" "iperf3" "aireplay-ng" "iwconfig" "hostapd" "wpa_supplicant" "tmux" "iw")
    local missing_commands=()
    
    for cmd in "${required_commands[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            missing_commands+=("$cmd")
        fi
    done
    
    if [ ${#missing_commands[@]} -gt 0 ]; then
        echo -e "${RED}Missing required commands:${NC}"
        for cmd in "${missing_commands[@]}"; do
            echo -e "${RED}- $cmd${NC}"
        done
        return 1
    fi
    
    # Check for config file
    if [ ! -f "config.sh" ]; then
        echo -e "${RED}Error: config.sh not found${NC}"
        return 1
    fi
    
    # Check for logs directory
    if [ ! -d "logs" ]; then
        mkdir -p "logs"
        echo -e "${GREEN}Created logs directory${NC}"
    fi
    
    echo -e "${GREEN}All system requirements met!${NC}"
    return 0
}

# Function to initialize test environment
initialize_environment() {
    echo -e "\n${CYAN}Initializing test environment...${NC}"
    
    # Run the initialization script
    if [ -f "init.sh" ]; then
        bash init.sh
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}Test environment initialized successfully!${NC}"
            return 0
        else
            echo -e "${RED}Failed to initialize test environment${NC}"
            return 1
        fi
    else
        echo -e "${RED}Error: init.sh not found${NC}"
        return 1
    fi
}

# Function to show about information
show_about() {
    clear
    echo -e "${ORBITRON_ART}"
    echo -e "     ${YELLOW}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "     ${YELLOW}║${NC}                      ${GREEN}About ORBITRON${NC}                      ${YELLOW}║${NC}"
    echo -e "     ${YELLOW}╠══════════════════════════════════════════════════════════╣${NC}"
    echo -e "     ${YELLOW}║${NC}                                                          ${YELLOW}║${NC}"
    echo -e "     ${YELLOW}║${NC}  ${CYAN}Created by:${NC} Shahab Afshar                               ${YELLOW}║${NC}"
    echo -e "     ${YELLOW}║${NC}  ${CYAN}Course:${NC} Wireless Network Security                       ${YELLOW}║${NC}"
    echo -e "     ${YELLOW}║${NC}  ${CYAN}Professor:${NC} Dr. Mohamed Selim                            ${YELLOW}║${NC}"
    echo -e "     ${YELLOW}║${NC}                                                          ${YELLOW}║${NC}"
    echo -e "     ${YELLOW}║${NC}  ${GREEN}ORBITRON${NC} is a comprehensive network testing suite       ${YELLOW}║${NC}"
    echo -e "     ${YELLOW}║${NC}  designed for wireless network security analysis and     ${YELLOW}║${NC}"
    echo -e "     ${YELLOW}║${NC}  performance evaluation.                                 ${YELLOW}║${NC}"
    echo -e "     ${YELLOW}║${NC}                                                          ${YELLOW}║${NC}"
    echo -e "     ${YELLOW}╚══════════════════════════════════════════════════════════╝${NC}"
    echo -e "\n${PURPLE}Press Enter to return to main menu...${NC}"
    read
}

# Function to display the menu
show_menu() {
    clear
    echo -e "     ${ORBITRON_ART}"
    echo -e "     ${YELLOW}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "     ${YELLOW}║${NC}                   ${GREEN}ORBITRON Test Suite${NC}                    ${YELLOW}║${NC}"
    echo -e "     ${YELLOW}╠══════════════════════════════════════════════════════════╣${NC}"
    echo -e "     ${YELLOW}║${NC}  ${CYAN}1.${NC} Initialize Test Environment                          ${YELLOW}║${NC}"
    echo -e "     ${YELLOW}║${NC}  ${CYAN}2.${NC} Setup Nodes                                          ${YELLOW}║${NC}"
    echo -e "     ${YELLOW}║${NC}  ${CYAN}3.${NC} Run TCP Saturation Test                              ${YELLOW}║${NC}"
    echo -e "     ${YELLOW}║${NC}  ${CYAN}4.${NC} Run UDP Saturation Test                              ${YELLOW}║${NC}"
    echo -e "     ${YELLOW}║${NC}  ${CYAN}5.${NC} Run WiFi Jamming Test                                ${YELLOW}║${NC}"
    echo -e "     ${YELLOW}║${NC}  ${CYAN}6.${NC} Run All Tests                                        ${YELLOW}║${NC}"
    echo -e "     ${YELLOW}║${NC}  ${CYAN}7.${NC} View Test Results                                    ${YELLOW}║${NC}"
    echo -e "     ${YELLOW}║${NC}  ${CYAN}8.${NC} Configure Test Parameters                            ${YELLOW}║${NC}"
    echo -e "     ${YELLOW}║${NC}  ${CYAN}9.${NC} About ORBITRON                                       ${YELLOW}║${NC}"
    echo -e "     ${YELLOW}║${NC}  ${CYAN}10.${NC} Exit                                                ${YELLOW}║${NC}"
    echo -e "     ${YELLOW}╚══════════════════════════════════════════════════════════╝${NC}"
    echo -e "\n${PURPLE}Select an option:${NC} "
}

# Function to display test results
show_results() {
    clear
    echo -e "${ORBITRON_ART}"
    echo -e "${YELLOW}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}║${NC}                   ${GREEN}Test Results${NC}                           ${YELLOW}║${NC}"
    echo -e "${YELLOW}╠══════════════════════════════════════════════════════════╣${NC}"
    echo -e "${YELLOW}║${NC}                                                          ${YELLOW}║${NC}"
    echo -e "${YELLOW}║${NC}  ${RED}Note:${NC} ORBIT testbed does not support Jupyter            ${YELLOW}║${NC}"
    echo -e "${YELLOW}║${NC}  Notebook. Please copy the log files to your local       ${YELLOW}║${NC}"
    echo -e "${YELLOW}║${NC}  system to run the analysis.                             ${YELLOW}║${NC}"
    echo -e "${YELLOW}║${NC}                                                          ${YELLOW}║${NC}"
    echo -e "${YELLOW}╚══════════════════════════════════════════════════════════╝${NC}"
    echo -e "\n${PURPLE}Press Enter to return to main menu...${NC}"
    read
}

# Function to configure test parameters
configure_tests() {
    clear
    echo -e "${ORBITRON_ART}"
    echo -e "${YELLOW}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}║${NC}                ${GREEN}Test Configuration${NC}                    ${YELLOW}║${NC}"
    echo -e "${YELLOW}╠══════════════════════════════════════════════════════════╣${NC}"
    
    # Read current configuration
    if [ -f "config.sh" ]; then
        source config.sh
        echo -e "${YELLOW}║${NC}  ${CYAN}1.${NC} Test Duration (current: ${TEST_DURATION}s)        ${YELLOW}║${NC}"
        echo -e "${YELLOW}║${NC}  ${CYAN}2.${NC} Return to Main Menu                              ${YELLOW}║${NC}"
        echo -e "${YELLOW}╚══════════════════════════════════════════════════════════╝${NC}"
        echo -e "\n${PURPLE}Select an option:${NC} "
        read -r config_choice
        
        case $config_choice in
            1)
                echo -e "\n${PURPLE}Enter new test duration (in seconds):${NC} "
                read -r new_duration
                if [[ "$new_duration" =~ ^[0-9]+$ ]]; then
                    # Use sed to update the config file
                    sed -i "s/TEST_DURATION=.*/TEST_DURATION=$new_duration/" config.sh
                    echo -e "${GREEN}Test duration updated successfully!${NC}"
                else
                    echo -e "${RED}Invalid duration. Please enter a number.${NC}"
                fi
                sleep 2
                ;;
            2)
                return
                ;;
            *)
                echo -e "${RED}Invalid option${NC}"
                sleep 2
                ;;
        esac
    else
        echo -e "${RED}Error: config.sh not found${NC}"
        sleep 2
    fi
}

# Main menu loop
while true; do
    show_menu
    read -r choice
    
    case $choice in
        1)
            initialize_environment
            ;;
        2)
            if [ -f "setup.sh" ]; then
                echo -e "\n${GREEN}Running Node Setup...${NC}"
                bash setup.sh
            else
                echo -e "${RED}Error: setup.sh not found${NC}"
            fi
            ;;
        3)
            if [ -f "run_tests.sh" ]; then
                echo -e "\n${GREEN}Running TCP Saturation Test...${NC}"
                bash run_tests.sh tcp
            else
                echo -e "${RED}Error: run_tests.sh not found${NC}"
            fi
            ;;
        4)
            if [ -f "run_tests.sh" ]; then
                echo -e "\n${GREEN}Running UDP Saturation Test...${NC}"
                bash run_tests.sh udp
            else
                echo -e "${RED}Error: run_tests.sh not found${NC}"
            fi
            ;;
        5)
            if [ -f "run_tests.sh" ]; then
                echo -e "\n${GREEN}Running WiFi Jamming Test...${NC}"
                bash run_tests.sh wifi
            else
                echo -e "${RED}Error: run_tests.sh not found${NC}"
            fi
            ;;
        6)
            if [ -f "run_tests.sh" ]; then
                echo -e "\n${GREEN}Running All Tests...${NC}"
                bash run_tests.sh all
            else
                echo -e "${RED}Error: run_tests.sh not found${NC}"
            fi
            ;;
        7)
            show_results
            ;;
        8)
            configure_tests
            ;;
        9)
            show_about
            ;;
        10)
            echo -e "\n${GREEN}Thank you for using ORBITRON!${NC}"
            exit 0
            ;;
        *)
            echo -e "\n${RED}Invalid option. Please try again.${NC}"
            sleep 2
            ;;
    esac

    if [ "$choice" != "7" ] && [ "$choice" != "8" ] && [ "$choice" != "9" ]; then
        echo -e "\n${PURPLE}Press Enter to return to main menu...${NC}"
        read
    fi
done 