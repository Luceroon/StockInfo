*** Settings ***
Documentation       Hae eri yrityksiä ja niiden tietoja käyttämällä erilaisa rajapintoja

Library    RPA.HTTP
Library    RPA.JSON
Library    RPA.Robocorp.Vault
Library    Collections  
Library    OperatingSystem
Library    RPA.Assistant
Library    RPA.Netsuite
*** Variables ***
${intraday_value}    Intraday

*** Tasks ***
Main
    Choosing Subject Matter
    ${result}    RPA.Assistant.Run Dialog    title=StockInfo    on_top=True    height=450

    

*** Keywords ***
Choosing Subject Matter
    [Documentation]
    ...    Main UI of the bot. We use the "Back To Main Menu" keyword
    ...    with buttons to make other views return here.
    Clear Dialog
    Add Heading    StockInfo Robot
    Add Text    Select:
    Add Button    Market News & Sentiment    Market News and Sentiment
    Add Button    Stock Prices    Stock Prices
    Add Submit Buttons    buttons=Close    default=Close

Back To Main Menu
    [Documentation]
    ...    This keyword handles the results of the form whenever the "Back" button
    ...    is used, and then we return to the main menu
    [Arguments]    ${results}={}

    # Handle the dialog results via the passed 'results' -variable
    # Logging the user outputs directly is bad practice as you can easily expose things that should not be exposed
    IF    'password' in ${results}    Log To Console    Do not log user inputs!
    IF    'files' in ${results}
        Log To Console    Selected files: ${results}[files]
    END

    Choosing Subject Matter    #${secret}
    Refresh Dialog



Market News and Sentiment
    Clear Dialog
    Add Heading    Choose topics you want news about
    Open Row
    Open Column
    Add Checkbox    name=blockchain    label=Blockchains    
    Add Checkbox    name=earnings    label=Earnings
    Add Checkbox    name=ipo    label=IPO
    Add Checkbox    name=mergers_and_acquisitions    label=Mergers & Aquisition
    Add Checkbox    name=financial_markets    label=Financial Markets
    Close Column
    Open Column
    Add Checkbox    name=economy_fiscal    label=Economy - Fiscal Policy
    Add Checkbox    name=economy_monetary    label=Economy - Monetary Policy
    Add Checkbox    name=economy_macro    label=Economy - Macro/Overall
    Add Checkbox    name= energy_transportation   label=Energy & Transportation
    Add Checkbox    name=finance    label=Finance
    Close Column
    Open Column
    Add Checkbox    name=life_sciences    label=Life Sciences
    Add Checkbox    name=manufacturing    label=Manufacturing
    Add Checkbox    name=real_estate    label=Real Estate & Construction
    Add Checkbox    name=retail_wholesale    label=Retail & Wholesale
    Add Checkbox    name=technology    label=Technology
    Close Column
    Close Row
    
    Add Submit Buttons    buttons=Submit
    Add Next Ui Button    Back    Back To Main menu
    Refresh Dialog

Stock Prices
    [Documentation]    Asks user for inputs so the robot knows what info to fetch
    Clear Dialog
    Add Heading    Input stock ticker
    Add Text Input    name=Ticker    label=Input stock ticker     maximum_rows=1
    Add Drop-Down    name=Time series    options=Intraday, Daily adjusted, Weekly, Monthly
    Add Date Input    name=Date
    Add Next Ui Button    Next    Create Variable For Results
    Add Next Ui Button    Back    Back To Main menu
    Refresh Dialog

Create Variable For Results
    [Documentation]    Creates a global variable for ${result} that we can later use if ${result} gets a new value
    [Arguments]    ${result}
    Set Global Variable    ${stock_price_inputs}    ${result}
    Log    ${stock_price_inputs}
    Is Interval Needed    ${result}

    
Is Interval Needed
    [Documentation]    Check if selected time series was Intraday. If it is you need to select an interval, else goes to the next step
    [Arguments]    ${result}
    ${value}    Get From Dictionary    ${result}    Time series
    IF    $value == $intraday_value
        Clear Dialog
        Add Heading    Select time interval
        Add Drop-Down    name=Interval    options=1min, 5min, 15min, 30min, 60min
        Add Next Ui Button    Next     Get Data From Api
        Add Button    Back    Stock Prices
        Refresh Dialog
    ELSE
        Get Data From Api    ${result}
    END       

Get Data From Api
    [Documentation]    Gets data from Alphavantage API using the parameters that user input
    [Arguments]    ${result}
    ${secret}    Get Secret    credentials

    ${time_series}    Get From Dictionary    ${stock_price_inputs}    Time series

    IF    $time_series==$intraday_value
        ${url}    Set Variable   https://www.alphavantage.co/query?function=TIME_SERIES_${stock_price_inputs}[Time series]&symbol=${stock_price_inputs}[Ticker]&interval=${result}[Interval]&apikey=${secret}[alphavantage_api_key]
        ${response}    Get   ${url}
        ${data}             Evaluate     json.loads('''${response.text}''')
        Save JSON to file    ${data}    StockPriceData.json
    ELSE
        ${url}    Set Variable   https://www.alphavantage.co/query?function=TIME_SERIES_${stock_price_inputs}[Time series]&symbol=${stock_price_inputs}[Ticker]&apikey=${secret}[alphavantage_api_key]
        ${response}    Get    ${url}
        ${data}    Evaluate    json.loads('''${response.text}''')
        Save JSON to file    ${data}    StockPriceData.json
    END
