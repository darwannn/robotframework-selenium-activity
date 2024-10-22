*** Settings ***
Library             SeleniumLibrary
Library             ../Libraries/Users.py
Variables           ../Variables/Variable.py
Library             Collections

Suite Setup         Lauch Browser, Load Data, And Login
Suite Teardown      Close Browser


*** Variables ***
@{new_users_list}       @{EMPTY}
@{no_orders_list}       @{EMPTY}


*** Test Cases ***
Test Case One
    Create Users
    Verify Created Users
    Display Users

Test Case Two
    Get Users Order Count
    Verify Empty Orders



*** Keywords ***
Lauch Browser, Load Data, And Login
    Launch Browser
    Login User    demo    demo
    Fetch API Data

Launch Browser
    [Arguments]    ${url}=https://marmelab.com/react-admin-demo/
    ${options}    Set Variable    add_argument("--start-maximized")
    Open Browser    ${url}    chrome    remote_url=192.168.56.1:4444    options=${options}

Login User
    [Arguments]    ${user}    ${password}
    Wait Until Element Is Visible    ${login_btn_submit}
    Input Text    //input[@name="username"]    ${user}
    Input Text    //input[@name="password"]    ${password}
    Click Button    ${login_btn_submit}

Go To Link
    [Arguments]    ${text}
    Click Element    //a[text()="${text}"]
    Wait Until Element Is Visible    ${table_body_row}

Fetch API Data
    ${users}    API Get Users
    Set Suite Variable    ${USERS}    ${users}

Open Create Identity Modal
    Click Element    ${identity_btn_create}
    Wait Until Element Is Visible    ${identity_txt_first_name}

Create Users
    FOR    ${user}    IN    @{USERS}
        Go To Link    Customers
        Open Create Identity Modal
        ${first_name}    Evaluate    " ".join("${user['name']}".split()[:-1]).strip()
        ${last_name}    Evaluate    " ".join("${user['name']}".split()[-1:]).strip()
        ${address}    Evaluate    f"${user['address']['suite']}, ${user['address']['street']}"
        ${password}    Generate User Password
        Input Text    ${identity_txt_first_name}    ${first_name}
        Input Text    ${identity_txt_last_name}    ${last_name}
        Input Text    ${identity_txt_email}    ${user['email']}
        Input Date    ${identity_txt_birthday}    ${user['birthday']}
        Input Text    ${identity_txt_address}    ${address}
        Input Text    ${identity_txt_city}    ${user['address']['city']}
        Input Text    ${identity_txt_state_abbr}    ${user['address']['state']}
        Input Text    ${identity_txt_zip_code}    ${user['address']['zipcode']}
        Input Password    ${identity_txt_password}    ${password}
        Sleep    .5s
        Input Password    ${identity_txt_confirm_password}    ${password}
        Click Button    ${identity_btn_save}
        Wait Until Element Is Visible    ${identity_btn_delete}    5s
        Append To List    ${new_users_list}    ${user['name']}
    END

Input Date
    [Arguments]    ${locator}    ${date}
    Click Element At Coordinates    ${locator}    0    0
    Press Keys    None    ${date}

Verify Created Users
    Go To Link    Customers
    Sleep    5s
    FOR    ${user}    IN    @{USERS}
        Page Should Contain    ${user['name']}
    END

Display Users
    ${row_count}    Get Table Row Count    ${table_body_row}
    FOR    ${i}    IN RANGE    1    ${row_count}+1
        Log To Console    \n\n----------User ${i}----------\n\n

        FOR    ${j}    IN RANGE    2    9
            ${table_header_locator}    Set Variable    (//thead//th)[${j}]
            ${table_header_value}    Get Text    ${table_header_locator}
            ${table_data_locator}    Set Variable    ((//tbody//tr)[${i}]//td)[${j}]
            ${table_data_value}    Get Text    ${table_data_locator}

            IF    ${j}==2
                ${data_has_image}    Run Keyword And Return Status    Page Should Contain Element
                ...    ${table_data_locator}//img

                IF    not ${data_has_image}
                    ${table_data_value}    Remove New Line    ${table_data_value}    ""
                    ${table_data_value}    Evaluate    "${table_data_value}"[1:]
                END

                IF    "${table_data_value}" in "${new_users_list}"
                    ${table_header_value}    Set Variable    Test Created User
                ELSE
                    ${table_header_value}    Set Variable    Existing User
                END
            END

            IF    ${j}==7
                ${table_data_value}    Get Element Attribute    (//tbody//td)[7]//*[name()="svg"]    aria-label
            END

            IF    ${j}==8
                ${table_data_value}    Remove New Line    ${table_data_value}    ","
            END
            Log To Console    ${table_header_value} : ${table_data_value}
        END
    END

Get Table Row Count
    [Arguments]    ${locator}
    ${web_elements}    Get WebElements    ${locator}
    ${row_count}    Get Length    ${web_elements}
    RETURN    ${row_count}

Remove New Line
    [Arguments]    ${value}    ${to_replace}
    ${new_value}    Evaluate    r"""${value}""".replace("\\n",${to_replace})
    RETURN    ${new_value}

Get Users Order Count
    Go To Link    Customers
    ${row_count}    Get Table Row Count    ${table_body_row}
    FOR    ${i}    IN RANGE    1    ${row_count}+1
        ${name_locator}    Set Variable    ((//tbody//tr)[${i}]//td)[2]
        ${name}    Get Text    ${name_locator}
        ${user_has_image}    Run Keyword And Return Status    Page Should Contain Element    ${name_locator}//img

        IF    not ${user_has_image}
            ${name}    Remove New Line    ${name}    ""
            ${name}    Evaluate    "${name}"[1:]
        END
        ${order_locator}    Set Variable    ((//tbody//tr)[${i}]//td)[4]
        ${order}    Get Text    ${order_locator}
        IF    ${order}==0    Append To List    ${no_orders_list}    ${name}
    END

Verify Empty Orders
    ${no_orders_count}    Get Length    ${no_orders_list}
    Should Be Equal As Numbers    ${no_orders_count}    0    Users with 0 orders found ${no_orders_list}
