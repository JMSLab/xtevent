---
output: github_document
---
# Smoothest paths for different settings of xtevent

We construct event studies using different numbers of leads and lags.
We solve for the smoothest path in each case.

## Summary data

We set the solver to "nr 5 bfgs". The solver finds a smoothest path in all cases. The optimal Wald value equals the Wald critical value in all cases.

There is a convergence error for pre=4, post=7. 

## Smooth outcome

### Post=2

| Pre=2 | Pre=3 | Pre=4 |
| ----- | ----- | ----- |
| ![](y_smooth_m_post2_pre2.png) | ![](y_smooth_m_post2_pre3.png) | ![](y_smooth_m_post2_pre4.png) |

| Pre=5 | Pre=6 | Pre=7 |
| ----- | ----- | ----- |
| ![](y_smooth_m_post2_pre5.png) | ![](y_smooth_m_post2_pre6.png) | ![](y_smooth_m_post2_pre7.png) |

### Post=3

| Pre=2 | Pre=3 | Pre=4 |
| ----- | ----- | ----- |
| ![](y_smooth_m_post3_pre2.png) | ![](y_smooth_m_post3_pre3.png) | ![](y_smooth_m_post3_pre4.png) |

| Pre=5 | Pre=6 | Pre=7 |
| ----- | ----- | ----- |
| ![](y_smooth_m_post3_pre5.png) | ![](y_smooth_m_post3_pre6.png) | ![](y_smooth_m_post3_pre7.png) |

### Post=4

| Pre=2 | Pre=3 | Pre=4 |
| ----- | ----- | ----- |
| ![](y_smooth_m_post4_pre2.png) | ![](y_smooth_m_post4_pre3.png) | ![](y_smooth_m_post4_pre4.png) |

| Pre=5 | Pre=6 | Pre=7 |
| ----- | ----- | ----- |
| ![](y_smooth_m_post4_pre5.png) | ![](y_smooth_m_post4_pre6.png) | ![](y_smooth_m_post4_pre7.png) |

### Post=5

| Pre=2 | Pre=3 | Pre=4 |
| ----- | ----- | ----- |
| ![](y_smooth_m_post5_pre2.png) | ![](y_smooth_m_post5_pre3.png) | ![](y_smooth_m_post5_pre4.png) |

| Pre=5 | Pre=6 | Pre=7 |
| ----- | ----- | ----- |
| ![](y_smooth_m_post5_pre5.png) | ![](y_smooth_m_post5_pre6.png) | ![](y_smooth_m_post5_pre7.png) |

### Post=6

| Pre=2 | Pre=3 | Pre=4 |
| ----- | ----- | ----- |
| ![](y_smooth_m_post6_pre2.png) | ![](y_smooth_m_post6_pre3.png) | ![](y_smooth_m_post6_pre4.png) |

| Pre=5 | Pre=6 | Pre=7 |
| ----- | ----- | ----- |
| ![](y_smooth_m_post6_pre5.png) | ![](y_smooth_m_post6_pre6.png) | ![](y_smooth_m_post6_pre7.png) |

### Post=7

| Pre=2 | Pre=3 | Pre=4 |
| ----- | ----- | ----- |
| ![](y_smooth_m_post7_pre2.png) | ![](y_smooth_m_post7_pre3.png) | ![](y_smooth_m_post7_pre4.png) |

| Pre=5 | Pre=6 | Pre=7 |
| ----- | ----- | ----- |
| ![](y_smooth_m_post7_pre5.png) | ![](y_smooth_m_post7_pre6.png) | ![](y_smooth_m_post7_pre7.png) |

## Jump outcome

### Post=2

| Pre=2 | Pre=3 | Pre=4 |
| ----- | ----- | ----- |
| ![](y_jump_m_post2_pre2.png) | ![](y_jump_m_post2_pre3.png) | ![](y_jump_m_post2_pre4.png) |

| Pre=5 | Pre=6 | Pre=7 |
| ----- | ----- | ----- |
| ![](y_jump_m_post2_pre5.png) | ![](y_jump_m_post2_pre6.png) | ![](y_jump_m_post2_pre7.png) |

### Post=3

| Pre=2 | Pre=3 | Pre=4 |
| ----- | ----- | ----- |
| ![](y_jump_m_post3_pre2.png) | ![](y_jump_m_post3_pre3.png) | ![](y_jump_m_post3_pre4.png) |

| Pre=5 | Pre=6 | Pre=7 |
| ----- | ----- | ----- |
| ![](y_jump_m_post3_pre5.png) | ![](y_jump_m_post3_pre6.png) | ![](y_jump_m_post3_pre7.png) |

### Post=4

| Pre=2 | Pre=3 | Pre=4 |
| ----- | ----- | ----- |
| ![](y_jump_m_post4_pre2.png) | ![](y_jump_m_post4_pre3.png) | ![](y_jump_m_post4_pre4.png) |

| Pre=5 | Pre=6 | Pre=7 |
| ----- | ----- | ----- |
| ![](y_jump_m_post4_pre5.png) | ![](y_jump_m_post4_pre6.png) | ![](y_jump_m_post4_pre7.png) |

### Post=5

| Pre=2 | Pre=3 | Pre=4 |
| ----- | ----- | ----- |
| ![](y_jump_m_post5_pre2.png) | ![](y_jump_m_post5_pre3.png) | ![](y_jump_m_post5_pre4.png) |

| Pre=5 | Pre=6 | Pre=7 |
| ----- | ----- | ----- |
| ![](y_jump_m_post5_pre5.png) | ![](y_jump_m_post5_pre6.png) | ![](y_jump_m_post5_pre7.png) |

### Post=6

| Pre=2 | Pre=3 | Pre=4 |
| ----- | ----- | ----- |
| ![](y_jump_m_post6_pre2.png) | ![](y_jump_m_post6_pre3.png) | ![](y_jump_m_post6_pre4.png) |

| Pre=5 | Pre=6 | Pre=7 |
| ----- | ----- | ----- |
| ![](y_jump_m_post6_pre5.png) | ![](y_jump_m_post6_pre6.png) | ![](y_jump_m_post6_pre7.png) |

### Post=7

| Pre=2 | Pre=3 | Pre=4 |
| ----- | ----- | ----- |
| ![](y_jump_m_post7_pre2.png) | ![](y_jump_m_post7_pre3.png) | ![](y_jump_m_post7_pre4.png) |

| Pre=5 | Pre=6 | Pre=7 |
| ----- | ----- | ----- |
| ![](y_jump_m_post7_pre5.png) | ![](y_jump_m_post7_pre6.png) | ![](y_jump_m_post7_pre7.png) |