define_pdn_grid \
    -macro \
    -instances ram0 \
    -name sram_macros_NS \
    -starts_with POWER \
    -halo "1.0 1.0"

add_pdn_connect \
    -grid sram_macros_NS \
    -layers "Metal4 Metal3"
