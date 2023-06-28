import pandas as pd
import plotly.graph_objects as go

def intraday_graph(stock_price_inputs):
    df = pd.read_json("StockPriceData.json").T

    # Create the text for candlestick chart (concatenate string with volume)
    text = ["Volume: " + str(vol) for vol in df["5. volume"].tolist()]

    # Create the candlestick chart
    candlestick_trace = go.Candlestick(
        x=df.index,
        name="Price",
        open=df['1. open'].tolist(),
        high=df['2. high'].tolist(),
        low=df['3. low'].tolist(),
        close=df['4. close'].tolist(),
        text=text,  # Use the modified text list
        yaxis='y'  # Use the primary y-axis
    )

    # Create the volume bars
    volume_trace = go.Bar(
        x=df.index,
        y=df["5. volume"].tolist(),
        marker=dict(color='rgba(0, 120, 200, 0.7)'),
        name='Volume',
        opacity=0.5,
        yaxis='y2'  # Use the secondary y-axis
    )

    # Create the Plotly figure
    fig = go.Figure(data=[candlestick_trace, volume_trace])

    # Configure the layout
    fig.update_layout(
        title=stock_price_inputs["Ticker"],
        xaxis_title='Date',
        yaxis_title='Price',
        hovermode='x unified',
        template='plotly_dark',
        xaxis=dict(
            type='category',
            autorange='reversed',
            showgrid=True,
            tickformat='%Y-%m-%d %H:%M:%S',
            dtick=10  # Specify the interval between tick labels
        ),
        yaxis=dict(
            title='Price',
            showgrid=True,
        ),
        yaxis2=dict(
            title='Volume',
            overlaying='y',
            side='right',
            showgrid=True,
        ),
        legend=dict(
            x=0.7,
            y=0.95,
            bgcolor='rgba(0,0,0,0)',
            bordercolor='rgba(255,255,255,0.5)',
            borderwidth=1,
        ),
        dragmode='zoom',
        xaxis_rangeslider_visible=False,
        xaxis_range=[df.index[0], df.index[50]]
    )

    # Show the figure
    fig.show()









def adjusted_graphs(stock_price_inputs):
    df = pd.read_json("StockPriceData.json").T

    # Convert the '5. adjusted close' column to numeric
    df['5. adjusted close'] = pd.to_numeric(df['5. adjusted close'])

    # Calculate the rolling average (90 days)
    rolling_average = df['5. adjusted close'].rolling(window=90).mean()

    # Create the Plotly figure
    fig = go.Figure()

    # Add the traces to the figure
    fig.add_trace(go.Scatter(
        x=df.index,
        y=df['5. adjusted close'],
        name='Adjusted Close',
        line=dict(color='steelblue', width=2),
        hovertemplate='<b>Date</b>: %{x}<br><b>Adjusted Close</b>: $%{y:.2f}',
    ))

    fig.add_trace(go.Scatter(
        x=df.index,
        y=rolling_average,
        name='Rolling Average (90 days)',
        line=dict(color='firebrick', width=2),
        hovertemplate='<b>Date</b>: %{x}<br><b>Rolling Average (90 days)</b>: $%{y:.2f}',
    ))

    # Configure the layout
    fig.update_layout(
        title=stock_price_inputs["Ticker"],
        xaxis_title='Date',
        yaxis_title='Value',
        hovermode='x unified',
        template='plotly_dark',
        xaxis=dict(tickformat='%Y-%m-%d'),
        legend=dict(
            x=0.7,
            y=0.95,
            bgcolor='rgba(0,0,0,0)',
            bordercolor='rgba(255,255,255,0.5)',
            borderwidth=1,
        ),
    )

    # Show the figure
    fig.show()