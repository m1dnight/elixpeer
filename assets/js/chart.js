function volumeFormatter(fileSizeInBytes, index) {
  if (fileSizeInBytes === 0) {
    return "0";
  }
  var i = -1;
  var byteUnits = [" KB", " MB", " GB", " TB", "PB", "EB", "ZB", "YB"];
  do {
    fileSizeInBytes = fileSizeInBytes / 1024;
    i++;
  } while (fileSizeInBytes > 1024);

  return Math.max(fileSizeInBytes, 0.1).toFixed(1) + byteUnits[i];
}

function rateFormatter(fileSizeInBytes, index) {
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
}

const defaultChartOptions = {
  type: "area",
  height: 300,
  stacked: true,
  foreColor: "white",
  toolbar: {
    theme: "dark",
  },
};

const defaultOptions = {
  colors: ["#03CEA4", "#FB4D3D"],
  stroke: {
    curve: "smooth",
    width: 1,
  },
  dataLabels: {
    enabled: false,
  },
  series: [],
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
      formatter: volumeFormatter,
    },
    tooltip: {
      enabled: true,
    },
  },
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
    colors: ["#03CEA4", "#FB4D3D"],
  },
};

export { volumeFormatter, rateFormatter, defaultChartOptions, defaultOptions };
