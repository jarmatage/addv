`timescale 1ns/1ps

interface read_if #(
    parameter DATA_WIDTH = 8
);

    logic                  clk;
    logic                  rst_n;
    logic                  en;
    logic [DATA_WIDTH-1:0] data;
    logic                  empty;
    logic                  almost_empty;

    modport dut (
        input clk, rst_n, en,
        output data, empty, almost_empty
    );

endinterface

interface write_if #(
    parameter DATA_WIDTH = 8
);

    logic                  clk;
    logic                  rst_n;
    logic                  en;
    logic [DATA_WIDTH-1:0] data;
    logic                  full;
    logic                  almost_full;

    modport dut (
        input clk, rst_n, en, data,
        output full, almost_full
    );

endinterface
