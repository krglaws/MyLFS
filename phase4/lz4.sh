#Lz4 Phase 4
make BUILD_STATIC=no PREFIX=/usr
make -jl check
make BUILD_STATIC=no PREFIX=/usr install
