# 璺嚎 Ultra 寮€鍙戜笌涓婃澘璁板綍

鏃ユ湡锛?026-07-04

## 1. 杈撳叆渚濇嵁

鏈疆宸ヤ綔渚濇嵁 `MCU_FFT_300MHz_extreme_optimization_report.pdf`锛岀洰鏍囨槸鎶?V10銆乂11銆乂12 涓夋浠?RTL 寮€鍙戞帹杩涘埌鏉垮崱瀹炵幇涓庤皟璇曢摼璺鏌ャ€?
## 2. 宸插畬鎴愬唴瀹?
1. 鏂板缓 `routes_ultra/`锛屽皢涓夋潯璺嚎鎷嗘垚鐙珛宸ョ▼鐩綍锛岄伩鍏嶅奖鍝?Route A 绋冲畾涓婃澘鐗堟湰銆?2. V10 瀹屾垚瀵勫瓨鍣ㄥ爢鍜?ALU 鏁版嵁閫氳矾瀹藉害缂╃獎锛?   - `reg_file` 浣跨敤 `DATA_W=25` 瀛樺偍锛岃鍑烘椂绗﹀彿鎵╁睍鍒?32 bit銆?   - ALU 鐨?ADD/SUB/MOV/MUL 浣跨敤 25/26 bit 鍐呴儴缁撴灉锛岃緭鍑哄啀鎵╁睍銆?3. V11 瀹屾垚鍙栨寚瀵勫瓨鍣ㄨ竟鐣岋細
   - 鏂板 `instr_id`锛屽皢 PC/ROM 杈撳嚭涓庤瘧鐮?瀵勫瓨鍣ㄨ/ALU 璺緞鍒嗗紑銆?   - 鍒嗘敮鏃舵彃鍏?NOP 姘旀场锛涘綋鍓?FFT 涓荤▼搴忔病鏈夊惊鐜垎鏀紝鍔熻兘椋庨櫓鍙帶銆?4. V12 瀹屾垚 MUL 澶氬懆鏈熸帶鍒讹細
   - `MUL` 鍚姩鍛ㄦ湡閿佸瓨鎿嶄綔鏁板拰鐩殑瀵勫瓨鍣ㄣ€?   - 涓嬩竴鍛ㄦ湡鍐欏洖涔樻硶缁撴灉骞舵帹杩?PC銆?   - 鏅€?ADD/SUB/LDR/STR/MOV/HALT 浠嶄繚鎸佸崟鍛ㄦ湡璺緞銆?5. 涓夋潯璺嚎鍧囧畬鎴愬畼鏂规牱渚嬪拰 20 缁勯殢鏈鸿緭鍏ュ洖褰掋€?6. 涓夋潯璺嚎鍧囧畬鎴?Vivado 缁煎悎銆佸疄鐜般€丏RC 鍜?bitstream 鐢熸垚銆?7. 宸查€氳繃 Vivado Hardware Manager 璇嗗埆寮€鍙戞澘 JTAG锛?   - `devices=xc7k160t_0`
   - `device=xc7k160t name=xc7k160t_0`

## 3. 褰撳墠 Vivado 缁撴灉

| 璺嚎 | PLL 杈撳嚭鐩爣 | cnt_test | WNS | TNS | LUT | FF | DSP | BRAM | 缁撹 |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | --- |
| V10_width_reduce | 150 MHz | 157 | -0.664 ns | -169.132 ns | 904 | 448 | 0 | 0 | bitstream 宸茬敓鎴愶紝浣嗘湭杩?setup timing |
| V11_2stage_core | 200 MHz | 157 | -1.319 ns | -427.209 ns | 902 | 481 | 0 | 0 | bitstream 宸茬敓鎴愶紝浣嗘湭杩?setup timing |
| V12_alu_pipe_300 | 300 MHz | 161 | -4.099 ns | -3121.943 ns | 1139 | 484 | 0 | 0 | bitstream 宸茬敓鎴愶紝浣嗙 300 MHz 浠嶆湁鏄庢樉宸窛 |

DRC 鍙ｅ緞锛氫笁鏉¤矾绾垮潎涓?0 Error锛屼粎淇濈暀涓庡師椤圭洰涓€鑷寸殑 `CFGBVS/CONFIG_VOLTAGE` warning銆?
## 4. 閲嶈鍒ゆ柇

V10/V11/V12 鐨勫紑鍙戙€佸洖褰掋€佺患鍚堛€佸疄鐜板拰 bitstream 鍧囧凡瀹屾垚锛屼絾楂橀鐩爣娌℃湁 timing-clean銆傚洜姝ゅ綋鍓嶄笉鑳芥妸 150/200/300 MHz 鐗堟湰浣滀负姝ｅ紡涓婃澘閫氳繃鐗堟湰銆?
浠?timing 缁撴灉鍙嶆帹锛?
- V10 鐨勫叧閿矾寰勭害涓?7.331 ns锛岀悊璁?Fmax 绾?136 MHz銆?- V11 鐨勫叧閿矾寰勭害涓?6.319 ns锛岀悊璁?Fmax 绾?158 MHz銆?- V12 鐨勫叧閿矾寰勭害涓?7.432 ns锛岀悊璁?Fmax 绾?134 MHz銆?
杩欒鏄庯細

- V10 鐨勫搴︾缉绐勭‘瀹為檷浣庝簡瀵勫瓨鍣ㄦ暟閲忥紝浣嗗叧閿矾寰勪粛闆嗕腑鍦ㄥ湴鍧€/澶栬鍒ゆ柇/鍐欏洖缁勫悎閾俱€?- V11 褰撳墠鍙垏鎺?PC/ROM 鍒拌瘧鐮佺殑璺緞锛屾病鏈夊垏鎺?reg_file -> ALU -> writeback 涓昏矾寰勶紝鎵€浠ュ Fmax 鎻愬崌鏈夐檺銆?- V12 灏?MUL 鍋氭垚澶氬懆鏈熷悗鍔熻兘姝ｇ‘锛屼絾鏅€氬湴鍧€鍜屽啓鍥炶矾寰勪粛鐒朵富瀵?timing锛?00 MHz 杩橀渶瑕佺湡姝ｇ殑 EX/WB 鍒嗙骇鎴栧湴鍧€璇戠爜瀵勫瓨銆?
## 5. 涓嬩竴姝ラ檷棰戜笂鏉垮缓璁?
寤鸿涓嶈鐩存帴涓嬭浇褰撳墠璐?WNS 鐨勯珮棰?bitstream銆備笅涓€杞鎸変笅闈㈤『搴忕敓鎴?timing-clean 鐗堟湰锛?
| 璺嚎 | 寤鸿闄嶉鐩爣 | PLL 鍙傛暟寤鸿 | 鐩爣 |
| --- | ---: | --- | --- |
| V10 | 130 MHz 鎴?135 MHz | 130 MHz: `MULT=26, DIV=10`; 135 MHz: `MULT=27, DIV=10` | 鍏堢‘璁ゅ搴︾缉绐勭増鑳界ǔ瀹氫笂鏉?|
| V11 | 150 MHz | `MULT=18, DIV=6` | 楠岃瘉鍙栨寚瀵勫瓨鍣ㄨ竟鐣屾槸鍚﹀彲绋冲畾杩愯 |
| V12 | 130 MHz | `MULT=26, DIV=10` | 楠岃瘉 MUL 澶氬懆鏈熸帶鍒跺湪鏉夸笂鍔熻兘姝ｇ‘ |

瀹屾垚闄嶉鐗堝悗锛屽啀鎵撳紑 ILA 浠呭仛涓€娆″姛鑳芥姄娉紝妫€鏌ワ細

- `done`
- `verify_we`
- `verify_addr`
- `verify_vector_out`
- `cnt_test`

鏈€缁堟彁浜ゆ垚缁╂椂缁х画鍏抽棴 ILA銆?
## 6. 鏂囦欢浣嶇疆

婧愭枃浠朵笌鎶ュ憡锛?
- `routes_ultra/V10_width_reduce/mcu_fft_v10_width_reduce/`
- `routes_ultra/V11_2stage_core/mcu_fft_v11_2stage_core/`
- `routes_ultra/V12_alu_pipe_300/mcu_fft_v12_alu_pipe_300/`

Vivado 鎶ュ憡锛?
- `*/results/vivado_board/board_timing_summary.rpt`
- `*/results/vivado_board/board_utilization.rpt`
- `*/results/vivado_board/board_drc.rpt`
- `*/results/vivado_board/board_methodology.rpt`

鏈満 bitstream锛?
- `D:/vivado_work/routes_ultra/mcu_fft_v10_width_reduce/mcu_fft_board.runs/impl_1/board_top.bit`
- `D:/vivado_work/routes_ultra/mcu_fft_v11_2stage_core/mcu_fft_board.runs/impl_1/board_top.bit`
- `D:/vivado_work/routes_ultra/mcu_fft_v12_alu_pipe_300/mcu_fft_board.runs/impl_1/board_top.bit`
