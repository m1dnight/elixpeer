// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html";
// Establish Phoenix Socket and LiveView configuration.
import { Socket } from "phoenix";
import { LiveSocket } from "phoenix_live_view";
import topbar from "../vendor/topbar";

let Hooks = {};

Hooks.Chart = {
  mounted() {
    const chartConfig = JSON.parse(this.el.dataset.config);
    const opts = JSON.parse(this.el.dataset.opts);
    const seriesData = JSON.parse(this.el.dataset.series);
    const colorsData = JSON.parse(this.el.dataset.colors);
    const metricData = this.el.dataset.metric;


    console.log(seriesData);
    var labelFormatter = function (val, index) {
      return val;
    };

    if (metricData === "volume") {
      labelFormatter = function (fileSizeInBytes, index) {
        if(fileSizeInBytes === 0) {
          return "0";
        }
        var i = -1;
        var byteUnits = [" KB", " MB", " GB", " TB", "PB", "EB", "ZB", "YB"];
        do {
          fileSizeInBytes = fileSizeInBytes / 1024;
          i++;
        } while (fileSizeInBytes > 1024);

        return Math.max(fileSizeInBytes, 0.1).toFixed(1) + byteUnits[i];
      };
    }

    if (metricData === "rate") {
      labelFormatter = function (fileSizeInBytes, index) {
        var i = -1;
        var byteUnits = [
          " kbps",
          " Mbps",
          " Gbps",
          " Tbps",
          "Pbps",
          "Ebps",
          "Zbps",
          "Ybps",
        ];
        do {
          fileSizeInBytes = fileSizeInBytes / 1024;
          i++;
        } while (fileSizeInBytes > 1024);

        return Math.max(fileSizeInBytes, 0.1).toFixed(1) + byteUnits[i];
      };
    }

    var options = Object.assign(
      {
        chart: Object.assign(
          {
            type: "area",
            height: 300,
            stacked: true,
            foreColor: "white",
            toolbar: {
              theme: "dark",
            },
            // dropShadow: {
            //   enabled: true,
            //   enabledSeries: [0],
            //   top: -2,
            //   left: 2,
            //   blur: 5,
            //   opacity: 0.06,
            // },
          },
          chartConfig
        ),
        colors: colorsData,
        stroke: {
          curve: "smooth",
          width: 1,
        },
        dataLabels: {
          enabled: false,
        },
        series: seriesData,
        // markers: {
        //   size: 0,
        //   strokeColor: "#fff",
        //   strokeWidth: 3,
        //   strokeOpacity: 1,
        //   fillOpacity: 0.5,
        //   hover: {
        //     size: 6,
        //   },
        // },
        xaxis: {
          type: "datetime",
          axisBorder: {
            show: false,
          },
          tickAmount: 10,
          axisTicks: {
            show: false,
          },
        },
        yaxis: {
          labels: {
            offsetX: 14,
            offsetY: -10,
            formatter: labelFormatter,
          },
          tooltip: {
            enabled: true,
          },
        },
        // grid: {
        //   padding: {
        //     left: -5,
        //     right: 5,
        //   },
        // },
        tooltip: {
          x: {
            format: "dd MMM yyyy",
          },
          theme: "dark",
        },
        legend: {
          position: "top",
          horizontalAlign: "left",
        },
        fill: {
          type: "solid",
          opacity: 0.2,
          colors: colorsData,
        },
      },
      opts
    );

    const chart = new ApexCharts(this.el, options);

    chart.render();
  },
};

let csrfToken = document
  .querySelector("meta[name='csrf-token']")
  .getAttribute("content");
let liveSocket = new LiveSocket("/live", Socket, {
  hooks: Hooks,
  params: { _csrf_token: csrfToken },
});

// Show progress bar on live navigation and form submits
topbar.config({ barColors: { 0: "#29d" }, shadowColor: "rgba(0, 0, 0, .3)" });
window.addEventListener("phx:page-loading-start", (_info) => topbar.show(300));
window.addEventListener("phx:page-loading-stop", (_info) => topbar.hide());

// connect if there are any LiveViews on the page
liveSocket.connect();

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket;
