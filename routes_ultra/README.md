# routes_ultra锛歏10/V11/V12 楂橀鏋侀檺璺嚎

鏈洰褰曞瓨鏀炬牴鎹?`MCU_FFT_300MHz_extreme_optimization_report.pdf` 钀藉湴鐨勪笁鏉￠珮棰戝疄楠岃矾绾裤€備笁鏉¤矾绾垮潎浠庡凡涓婃澘鐨?Route A `speed_v7_q7_narrow_mul` 娲剧敓锛屼繚鎸?`xc7k160tffg676-2`銆乣flatten_hierarchy=none`銆乣max_dsp=0`銆佹寮忕粺璁″叧闂?ILA 鐨勫彛寰勩€?
## 璺嚎缁撴瀯

| 璺嚎 | 宸ョ▼鐩綍 | 鏈疆 RTL 鏀瑰姩 | 鐩爣鏉夸笂鏃堕挓 |
| --- | --- | --- | --- |
| V10 | `V10_width_reduce/mcu_fft_v10_width_reduce` | 瀵勫瓨鍣ㄥ爢鏀逛负 25 bit 瀛樺偍锛屽澶栫鍙锋墿灞曪紱ALU 鍐呴儴 ADD/SUB/MOV/MUL 閲囩敤绐勪綅瀹界粨鏋滃啀鎵╁睍銆?| 150 MHz |
| V11 | `V11_2stage_core/mcu_fft_v11_2stage_core` | 缁ф壙 V10锛屽苟澧炲姞 `instr_id` 鍙栨寚瀵勫瓨鍣紝灏?PC/ROM 涓庤瘧鐮?瀵勫瓨鍣ㄨ/ALU 鍒嗗紑銆?| 200 MHz |
| V12 | `V12_alu_pipe_300/mcu_fft_v12_alu_pipe_300` | 缁ф壙 V10锛屽苟灏?`MUL` 鏀逛负鍚姩/鍐欏洖涓ゅ懆鏈熸帶鍒讹紝鏅€氭寚浠や粛鍗曞懆鏈熴€?| 300 MHz |

## 褰撳墠缁撹

涓夋潯璺嚎鍧囧凡瀹屾垚鏈湴鍔熻兘鍥炲綊銆乂ivado 缁煎悎銆佸疄鐜般€丏RC 鍜?bitstream 鐢熸垚锛涘紑鍙戞澘 JTAG 閾捐矾涔熷凡璇嗗埆鍒?`xc7k160t_0`銆備絾鏄笁鏉￠珮棰戠洰鏍囧潎鏈弧瓒?post-route setup timing锛屽洜姝よ繖浜?bitstream 鍙兘浣滀负鏋侀檺瀹為獙浜х墿锛屼笉鑳戒綔涓衡€滈珮棰戜笂鏉块€氳繃鈥濈殑鏈€缁堟垚缁╂彁浜ゃ€?
| 璺嚎 | 鍥炲綊 | cnt_test | 鐩爣棰戠巼 | 鍗曟鏃堕棿浼扮畻 | WNS | LUT | FF | DSP | DRC |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | --- |
| V10 | PASS锛屽畼鏂规牱渚?+ 20 闅忔満 | 157 | 150 MHz | 1.047 us | -0.664 ns | 904 | 448 | 0 | 0 Error锛孋FGBVS warning |
| V11 | PASS锛屽畼鏂规牱渚?+ 20 闅忔満 | 157 | 200 MHz | 0.785 us | -1.319 ns | 902 | 481 | 0 | 0 Error锛孋FGBVS warning |
| V12 | PASS锛屽畼鏂规牱渚?+ 20 闅忔満 | 161 | 300 MHz | 0.537 us | -4.099 ns | 1139 | 484 | 0 | 0 Error锛孋FGBVS warning |

## 杩愯鍛戒护

鏈湴鍥炲綊锛?
```powershell
cd routes_ultra\V10_width_reduce\mcu_fft_v10_width_reduce
py scripts\run_official_regression.py --random-cases 20 --seed 2026
```

鏃?ILA 鏉垮崱瀹炵幇锛?
```powershell
cd routes_ultra\V10_width_reduce\mcu_fft_v10_width_reduce
D:\vivado\2025.2\Vivado\bin\vivado.bat -mode batch -source ..\..\vivado\run_no_ila_board_bitstream.tcl
```

涓夋潯璺嚎鐨?bitstream 杈撳嚭浣嶄簬锛?
```text
D:/vivado_work/routes_ultra/mcu_fft_v10_width_reduce/mcu_fft_board.runs/impl_1/board_top.bit
D:/vivado_work/routes_ultra/mcu_fft_v11_2stage_core/mcu_fft_board.runs/impl_1/board_top.bit
D:/vivado_work/routes_ultra/mcu_fft_v12_alu_pipe_300/mcu_fft_board.runs/impl_1/board_top.bit
```

## 涓婃澘鐘舵€?
宸插畬鎴愮‖浠堕摼璺瘑鍒細

```text
devices=xc7k160t_0
device=xc7k160t name=xc7k160t_0
```

鐢变簬 V10/V11/V12 褰撳墠楂橀瀹炵幇 WNS 鍧囦负璐熸暟锛屾湰杞病鏈夋妸瀹冧滑鏍囪涓洪珮棰戜笂鏉块€氳繃銆備笅涓€姝ュ缓璁厛鎸?`璺嚎Ultra寮€鍙戜笂鏉胯褰?md` 鐨勯檷棰戠煩闃电敓鎴?timing-clean bitstream锛屽啀鍋?ILA 鎶撴尝楠岃瘉銆?
