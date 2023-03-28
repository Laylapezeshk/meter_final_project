*** Setting ***
Documentation    Welcome to Meter's QA Engineer Take-Home Challenge!
...              Example keywords for Python's "ipaddress" module are
...              included to get you started. Feel free to modify these
...              starter files as needed!

Library    RequestsLibrary
Library    JSONLibrary
Library    String
Library    OperatingSystem
Library    Ipaddress


*** Variables ***
${BASE_URL}    https://moc-noc-api.deta.dev


*** Test Cases ***

Check DHCP Range Valid For Interface IP Addresses
    [Documentation]    Check DHCP Range is valid.

     Create Session  API_Testing   ${Base_URL}
     ${response}=    RequestsLibrary.GET  ${Base_URL}

    #Validation
    ${status_code}=     Convert To String    ${response.status_code}
    Should Be Equal    ${status_code}    200
    #Log To Console    ${response.content}

    ${body}=    Set Variable    ${response.content}
    ${body_json}=   Convert To String    ${body}
    ${body_dict}    Evaluate   json.loads("""${body_json}""")   modules=json


    ${interface_ip_address_guest}=  Set Variable      ${body_dict['moc-noc.v1.network.guest']['dhcp']['gateway']}
    ${dhcp_guest_ip_range}=     Set Variable    ${body_dict['moc-noc.v1.network.guest']['dhcp']['ip-range']}

    ${first_octet}         ${second_octet}    ${third_octet}   ${forth_octet}    Split String    ${interface_ip_address_guest}  .
    ${dhcp_start_ip_guest}        ${dhcp_end_ip_guest}       Split String    ${dhcp_guest_ip_range}    -


    ${first_end_dhcp}    ${second_end_dhcp}  ${third_end_dhcp}  ${forth_end_dhcp}   Split String    ${dhcp_end_ip_guest}      .

    
    ${first_start_dhcp}    ${second_start_dhcp}  ${third_start_dhcp}  ${forth_start_dhcp}   Split String    ${dhcp_start_ip_guest}      .


    ${valid_range}=    Evaluate    int(${forth_start_dhcp}) <= int(${forth_octet}) <= int(${forth_end_dhcp})

    Run Keyword If    ${valid_range}    Log    DHCP range is valid for interface IP address
    ...    ELSE    Log    DHCP range is NOT valid for interface IP address


    #${is_in_dhcp_range} =    Is IP Address in DHCP Range    ${interface_ip_address_guest}    ${dhcp_start_ip_guest}    ${dhcp_end_ip_guest}
    #${ip_address_obj} =    Convert To IPv4Address    ${interface_ip_address_guest}
    #${dhcp_range_start_obj}=    Convert To IPv4Address    ${dhcp_start_ip_guest}
    #Log To Console    ${ip_address_obj}
    #Log To Console    ${dhcp_range_start_obj}
    #Should Be True    ${is_in_dhcp_range}}



Check IP Addresses are Private
    [Documentation]    Check IP Addresses are Private.
    Create Session  API_Testing   ${Base_URL}
    ${response}=    RequestsLibrary.GET  ${Base_URL}

    #Validation
    ${status_code}=     Convert To String    ${response.status_code}
    Should Be Equal    ${status_code}    200
    Log To Console    ${response.content}

    ${body}=    Set Variable    ${response.content}
    ${body_json}=   Convert To String    ${body}
    ${body_dict}    Evaluate   json.loads("""${body_json}""")   modules=json


    ${interface_ip_address_guest}=  Set Variable      ${body_dict['moc-noc.v1.network.guest']['dhcp']['gateway']}
    ${interface_ip_address_corp}=  Set Variable      ${body_dict['moc-noc.v1.network.corp']['dhcp']['gateway']}

    ${ip_address_guest}    Run And Return Rc And Output    ipcalc -p ${interface_ip_address_guest}    # use ipcalc command to check if private
    ${ip_address_corp}    Run And Return Rc And Output    ipcalc -p ${interface_ip_address_corp}    # use ipcalc command to check if private

    Should Not Be Equal As Strings    ${ip_address_guest[1]}    0    # check if ipcalc returns "private" (1) or not (0)
    Should Not Be Equal As Strings    ${ip_address_corp[1]}    0    # check if ipcalc returns "private" (1) or not (0)



DHCP server netmask matches the VLSM subnet
    [Documentation]    Compare DHCP server netmask with VLSM subnet .
    Create Session  API_Testing   ${Base_URL}
    ${response}=    RequestsLibrary.GET  ${Base_URL}


    #Validation
    ${status_code}=     Convert To String    ${response.status_code}
    Should Be Equal    ${status_code}    200
    Log To Console    ${response.content}

    ${body}=    Set Variable    ${response.content}
    ${body_json}=   Convert To String    ${body}
    ${body_dict}    Evaluate   json.loads("""${body_json}""")   modules=json

    ${dhcp_netmask_corp}=    Set Variable      ${body_dict['moc-noc.v1.network.corp']['dhcp']['netmask']}
    Log To Console     ${dhcp_netmask_corp}
    ${vlsm_subnet_corp}=    Set Variable      ${body_dict['moc-noc.v1.network.corp']['ip-address']}
    Log To Console   ${vlsm_subnet_corp}

    ${sub}=    Split String    ${vlsm_subnet_corp}  /
    ${vlsm_sub}=  Set Variable  ${sub[1]}

    Log To Console    ${vlsm_sub}
    ${subnet_mask}=  Set Variable  ${vlsm_sub}
    ${dotted_decimal}=  Evaluate  '.'.join([str((0xffffffff << (32 - int(${subnet_mask}))) >> i & 0xff) for i in range(24, -8, -8)])
    Log To Console    ${dotted_decimal}
    Log To Console    ${dhcp_netmask_corp}
    should Be Equal As Strings   ${dotted_decimal}    ${dhcp_netmask_corp}



*** Keywords ***
Is IP Address in DHCP Range
    [Arguments]    ${ip_address}    ${dhcp_range_start}    ${dhcp_range_end}
    ${ip_address_obj} =    Convert To IPv4Address    ${ip_address}
    ${dhcp_range_start_obj} =    Convert To IPv4Address    ${dhcp_range_start}
    ${dhcp_range_end_obj} =    Convert To IPv4Address    ${dhcp_range_end}
    ${is_in_dhcp_range} =    Evaluate    ${dhcp_range_start_obj} <= ${ip_address_obj}pw <= ${dhcp_range_end_obj}
    [Return]    ${is_in_dhcp_range}

Convert To IPv4Address
    [Arguments]    ${ip_address}
    [Return]    ${ipaddress.IPv4Address}("${ip_address}")



