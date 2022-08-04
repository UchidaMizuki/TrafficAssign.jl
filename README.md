TrafficAssig.jl
================

TrafficAssig is a Julia package for…

1.  Load [Transportation
    Networks](https://github.com/bstabler/TransportationNetworks) data
    or construct traffic data from data frames.
2.  Traffic assignment with User Equilibrium.

## Load traffic data

You can load [Transportation
Networks](https://github.com/bstabler/TransportationNetworks) data
([TNTP](https://www.bgu.ac.il/~bargera/tntp/) format) with
`load_tntp()`.

``` julia
using TrafficAssig

tntp = load_tntp("Anaheim")
```

    Number of nodes: 416
    Trips:
    1406×3 DataFrame
      Row │ orig   dest   trips
          │ Int64  Int64  Float64
    ──────┼───────────────────────
        1 │     1      2   1365.9
        2 │     1      3    407.4
        3 │     1      4    861.4
        4 │     1      5    354.4
        5 │     1      6    545.1
        6 │     1      7    431.5
        7 │     1      8      1.0
        8 │     1      9     56.8
      ⋮   │   ⋮      ⋮       ⋮
     1400 │    38     31     84.2
     1401 │    38     32     25.1
     1402 │    38     33     24.6
     1403 │    38     34     31.1
     1404 │    38     35     21.4
     1405 │    38     36     19.1
     1406 │    38     37      2.3
                 1391 rows omitted

    Network:
    914×8 DataFrame
     Row │ from   to     free_flow_time  capacity  alpha    beta     toll     leng ⋯
         │ Int64  Int64  Float64         Float64   Float64  Float64  Float64  Floa ⋯
    ─────┼──────────────────────────────────────────────────────────────────────────
       1 │     1    117         1.09046    9000.0     0.15      4.0      0.0   528 ⋯
       2 │     2     87         1.09046    9000.0     0.15      4.0      0.0   528
       3 │     3     74         1.09046    9000.0     0.15      4.0      0.0   528
       4 │     4    233         1.09046    9000.0     0.15      4.0      0.0   528
       5 │     5    165         1.09046    9000.0     0.15      4.0      0.0   528 ⋯
       6 │     6    213         1.09046    9000.0     0.15      4.0      0.0   528
       7 │     7    253         1.09046    9000.0     0.15      4.0      0.0   528
       8 │     8    411         1.0        5400.0     0.15      4.0      0.0   264
      ⋮  │   ⋮      ⋮          ⋮            ⋮         ⋮        ⋮        ⋮        ⋮ ⋱
     908 │   413    404         2.0        5400.0     0.15      4.0      0.0   528 ⋯
     909 │   414     22         1.0        5400.0     0.15      4.0      0.0   264
     910 │   414    405         2.0        5400.0     0.15      4.0      0.0   528
     911 │   415     22         1.0        5400.0     0.15      4.0      0.0   264
     912 │   415    406         2.0        5400.0     0.15      4.0      0.0   528 ⋯
     913 │   416     23         1.0        5400.0     0.15      4.0      0.0   264
     914 │   416    407         2.0        5400.0     0.15      4.0      0.0   528
                                                       1 column and 899 rows omitted

## Traffic assignment

``` julia
res = assign_traffic(tntp)
res.flow
```

    frank_wolfe_results (generic function with 1 method)

    (914×3 DataFrame
     Row │ from   to     flow
         │ Int64  Int64  Float64
    ─────┼──────────────────────────
       1 │     1    117   7074.9
       2 │     2     87   9662.5
       3 │     3     74   7669.0
       4 │     4    233  12173.8
       5 │     5    165   2586.8
       6 │     6    213   6576.6
       7 │     7    253   7137.1
       8 │     8    411    722.1
      ⋮  │   ⋮      ⋮        ⋮
     908 │   413    404   1245.3
     909 │   414     22    509.4
     910 │   414    405    619.8
     911 │   415     22    934.2
     912 │   415    406    904.6
     913 │   416     23    387.9
     914 │   416    407   1522.5
                    899 rows omitted, 10×3 DataFrame
     Row │ exec_time  objective  relative_gap
         │ Float64    Float64    Float64
    ─────┼────────────────────────────────────
       1 │     0.285  1.29192e6   0.0253178
       2 │     0.878  1.2879e6    0.0029391
       3 │     0.925  1.28717e6   0.00237717
       4 │     0.995  1.28626e6   0.00115794
       5 │     1.273  1.28622e6   0.000541186
       6 │     1.322  1.2862e6    0.000523331
       7 │     1.369  1.28614e6   0.000476912
       8 │     1.431  1.28608e6   0.000161641
       9 │     1.484  1.28607e6   0.000144621
      10 │     1.52   1.28605e6   9.14319e-5)

    "README_files/frank-wolfe-results/Anaheim/flow.csv"

    "README_files/frank-wolfe-results/Anaheim/logs.csv"

![](README_files/figure-gfm/Plot%20a%20network-1.png)

## Traffic assignment algorithms

``` julia
tntp = load_tntp("GoldCoast")

res_FW = assign_traffic(tntp, algorithm=FrankWolfe())
res_CFW = assign_traffic(tntp, algorithm=ConjugateFrankWolfe())
res_BFW = assign_traffic(tntp, algorithm=BiconjugateFrankWolfe())
```

<img src="README_files/figure-gfm/Plot%20frank-wolfe%20results-J1.png"
width="600" />

<!-- ## Comparisons -->
