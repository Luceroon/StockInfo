*** Settings ***
Documentation       Hae eri yrityksiä ja niiden tietoja käyttämällä erilaisa rajapintoja

Library    RPA.HTTP
Library    RPA.JSON
Library    RPA.Robocorp.Vault
Library    Collections  
Library    OperatingSystem
Library    RPA.Assistant
Library    RPA.Netsuite
Library    RPA.Excel.Application
Library    Process
Library    RPA.Browser.Selenium
Library    Telnet
Library    DateTime
Library    Graphs.py

*** Variables ***
${intraday_value}    Intraday

*** Tasks ***
Main
    Choosing Subject Matter
    ${result}    RPA.Assistant.Run Dialog    title=StockInfo    on_top=True    width=720    height=AUTO    location=center    timeout=1800

    

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

    Choosing Subject Matter
    Refresh Dialog


Market News and Sentiment
    Clear Dialog
    Add Heading    Choose topics you want news about    size=large
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
    Add Checkbox    name=energy_transportation   label=Energy & Transportation
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
    
    Open Row
    Close Row
    Open Row
    Close Row
    Open Row
    Close Row
    Open Row
    Close Row

    Add Heading    Set date from and date to (Optional)    size=small
    Open Row
    Add Date Input    time_from    label=From
    Add Date Input    time_to    label=To (optional)
    Close Row

    Open Row
    Close Row
    Open Row
    Close Row
    Open Row
    Close Row
    Open Row
    Close Row

    Add Heading    Select sorting order for your news    size=small
    Open Row
    Add Drop-Down    
    ...    name=sorting_order    
    ...    options=Latest, Earliest, Relevance
    Close Row

    Open Row
    Close Row
    Open Row
    Close Row
    Open Row
    Close Row
    Open Row
    Close Row

    Add Heading    Type your stock/crypto/forex symbols of your choice. This will filter for articles that mention your symbol    size=small
    Add Text    For example:
    Add Image    symbol_example.PNG
    Open Row
    Add Text Input    tag_symbols    placeholder=Type your symbols
    Close Row

    Add Next Ui Button    Next    Fetch Market News and Sentiment
    Add Next Ui Button    Back    Back To Main menu
    Refresh Dialog



################################################################################################


Fetch Market News and Sentiment
    [Arguments]    ${result}

    ${secret}    Get Secret    credentials
    
    ${market_news_inputs}    Create Dictionary    tag_symbols=${EMPTY}    time_from=${EMPTY}    time_to=${EMPTY}    sorting_order=${EMPTY}
    FOR    ${key}    IN    @{result.keys()}
        IF    $result[$key] != False
        Set To Dictionary    ${market_news_inputs}    ${key}    ${result}[${key}]
        END
    END

    # Checks if user input anything into the text box. If user didn't input anything, None is changed to empty string.
    IF    $result.tag_symbols == None
        Set To Dictionary    ${market_news_inputs}    tag_symbols    ${EMPTY}
    END

    # Creates a list of topics that were selected in the dialog box. List is used in the url to fetch the right data from the API.
    ${topics}    Create List    
    FOR    ${item}    IN    &{result}
        IF    $item[1] == True
            Append To List    ${topics}    ${item}[0]
        END
    END
    ${topics_string}    Evaluate    ",".join(${topics})
   
    IF    "${market_news_inputs}[time_from]" != ""
        ${time_from}=    Convert Date    ${market_news_inputs}[time_from]     %Y%m%dT%H%M
    ELSE
        ${time_from}=    ${market_news_inputs}[time_from]
    END
    IF    "${market_news_inputs}[time_to]" != ""
        ${time_to}=    Convert Date    ${market_news_inputs}[time_to]     %Y%m%dT%H%M
    ELSE
        ${time_to}=    ${market_news_inputs}[time_to] 
    END

    ${url}    Set Variable    https://www.alphavantage.co/query?function=NEWS_SENTIMENT&tickers=${market_news_inputs.tag_symbols}&time_from=${time_from}&time_to=${time_to}&sort=${market_news_inputs.sorting_order}&topics=${topics_string}&apikey=${secret}[alphavantage_api_key]
    ${response}    Get    ${url}
    ${json_data}    Evaluate    json.loads(r'''${response.text}''')
    Save JSON to file    ${json_data}    MarketNews.json
    Market News Result    ${json_data}    ${market_news_inputs}



Market News Result
    [Arguments]    ${json_data}    ${market_news_inputs}
    TRY
        Clear Dialog
        Add Next Ui Button    Back    Back To Main menu
        FOR    ${article}    IN    @{json_data['feed']}
            ${parsed_date}    Convert Date    ${article['time_published']}    %Y-%m-%d %H:%M
            Add Heading    Title: ${article['title']}    size=medium
            Add Text    Source: ${article['source']}    size=large
            Add Text    Published: ${parsed_date}    size=large
            Add Text    Summary: ${article['summary']}    size=large
            Add Link    ${article['url']}    label=Read More 
        END
        Add Next Ui Button    Back    Back To Main menu
        Refresh Dialog        
    EXCEPT    #There was an error. Check your inputs.
        Add Heading    No news found with your inputs. Try other combinations of inputs.    
        Refresh Dialog
        Add Next Ui Button    Go back    Market News and Sentiment
    END



###########################################################################################################################################



Stock Prices
    [Documentation]    Asks user for inputs so the robot knows what info to fetch
    Clear Dialog
    Add Heading    Input stock ticker
    Add Text Input    name=Ticker    label=Input stock ticker     maximum_rows=1
    Add Drop-Down    name=Time series    options=Intraday, Daily_adjusted, Weekly_adjusted, Monthly_adjusted
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
    ${weekly}    Set Variable    Weekly_adjusted
    ${daily}    Set Variable    Daily_adjusted
    ${monthly}    Set Variable    Monthly_adjusted

    ${time_series}    Get From Dictionary    ${stock_price_inputs}    Time series

    IF    $time_series==$intraday_value
        ${url}    Set Variable   https://www.alphavantage.co/query?function=TIME_SERIES_${stock_price_inputs}[Time series]&symbol=${stock_price_inputs}[Ticker]&interval=${result}[Interval]&outputsize=full&apikey=${secret}[alphavantage_api_key]
        ${response}    Get   ${url}
        ${data}             Evaluate     json.loads('''${response.text}''')
        Log To Console    '${data}'
        Save JSON to file    ${data}[Time Series (${result}[Interval])]    StockPriceData.json
        # Calls intraday_graph from Graphs.py file 
        Intraday Graph    ${stock_price_inputs}
    ELSE
        ${url}    Set Variable   https://www.alphavantage.co/query?function=TIME_SERIES_${stock_price_inputs}[Time series]&symbol=${stock_price_inputs}[Ticker]&apikey=${secret}[alphavantage_api_key]
        ${response}    Get    ${url}
        ${data}    Evaluate    json.loads('''${response.text}''')
        IF    $time_series == $weekly
            Save JSON to file    ${data}[Weekly Adjusted Time Series]    StockPriceData.json
        ELSE IF    $time_series == $daily
            Save JSON to file    ${data}[Time Series (Daily)]    StockPriceData.json
        ELSE IF    $time_series == $monthly
            Save JSON to file    ${data}[Monthly Adjusted Time Series]    StockPriceData.json
        END
        # Calls adjusted_graphs from Graphs.py file
        Adjusted Graphs    ${stock_price_inputs}
    END

    
# Jatka Market News And Sentiment Juttua eteenpäin. Jos muuttujat linkissä ei saa arvoja niin heittää errorin pitää keksiä ratkaisu, että muuttujat voi jäädä tyhjiksi tai jtn.
# Selvittele miten saa time_from ja time_to toimimaan API url:ssä kun on väärässä muodossa. Käytä siihen datetime libraryä. Muuten jotain hienosäätöä uutisten kanssa kunnes valmis