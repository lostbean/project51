defmodule Area51.Web.PageHTML do
  use Area51.Web, :html

  def home(assigns) do
    ~H"""
    <!DOCTYPE html>
    <html lang="en">
      <head>
        <meta charset="utf-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <title>Area51 Terminal</title>

        <!-- Terminal fonts -->
        <link
          href="https://fonts.googleapis.com/css2?family=VT323&family=Share+Tech+Mono&display=swap"
          rel="stylesheet"
        />

        <!-- Custom terminal styles -->
        <link rel="stylesheet" href={~p"/app.css"} />
        <link rel="icon" type="image/png" href={~p"/favicon.ico"} />

        <!-- Your bundled JavaScript file -->
        <script defer type="text/javascript" src={~p"/assets/app.js"}></script>
      </head>
      <body>
        <div id="root"></div>
      </body>
    </html>
    """
  end
end
