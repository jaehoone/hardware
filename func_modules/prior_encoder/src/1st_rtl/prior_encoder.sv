module prior_encoder
#(
    parameter DATA_WIDTH                            = 8,
    parameter INDEX_WIDTH                           = $clog2(DATA_WIDTH)+1
)
(
    input  logic [DATA_WIDTH-1:0]                   data_in,
    output logic [INDEX_WIDTH-1:0]                  idx_out
);

    logic [DATA_WIDTH-1:0]                          data_mask;
    logic [INDEX_WIDTH-1:0]                         idx_found;

    genvar i;
    generate
        for(i=0; i<DATA_WIDTH; i++) begin
            always_comb begin
                if(data_in[(DATA_WIDTH-1)-i]) begin
                    data_mask[(DATA_WIDTH-1)-i]     = (|data_mask[(DATA_WIDTH-1)-:i+1]) ? 1'b0 : 1'b1;
                end
                else begin
                    data_mask[(DATA_WIDTH-1)-i]     = 1'b0;
                end
            end
        end
    endgenerate

    always_comb begin
        idx_found                                   = '0;

        for(int j=0; j<DATA_WIDTH; j++) begin
            if(|data_mask) begin
                if(data_mask[j]) begin
                    idx_found                       = j;
                end
            end
        end
    end

    always_comb begin
        idx_out                                     = '0;

        if(|data_in) begin
            idx_out                                 = idx_found;
        end
    end

endmodule