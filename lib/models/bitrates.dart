class BitRates {
  Map<int, String> map = {
    120000000: "120 Mb/s",
    100000000: "100 Mb/s",
    60000000: "60 Mb/s",
    40000000: "40 Mb/s",
    20000000: "20 Mb/s",
    8000000: "8 Mb/s",
    4000000: "4 Mb/s",
    2000000: "2 Mb/s",
    420000: "420 Kb/s",
  };

  int defaultBitrate() {
    return 8000000;
  }
}
