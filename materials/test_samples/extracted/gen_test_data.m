clear all;
close all;
clc;

rand('seed',100);
% 可以设置随机数种子，同一个随机数种子下的随机数序列相同

%%
fft_size = 8;                                       % fft点数
mat_size = 8;                                       % 向量长度
sort_size = 64;                                     % 排序长度
dct_size = 8;
test_times = 1;                                     % 生成几组随机数
sort_test_times = 10;
real_signal = zeros(test_times, fft_size);
imag_signal = zeros(test_times, fft_size);

DCT_signal_original  = zeros(test_times, dct_size);
sort_data_original   = zeros(sort_test_times, sort_size);

signal = zeros(test_times, fft_size) + zeros(test_times, fft_size)*1i;% 用于DFT变换的随机信号
signal_fft = zeros(test_times, fft_size);           % 完成DFT变换的信号
signal_fft_matlab = zeros(test_times, fft_size);    % 完成DFT变换的信号
signal_fft_compare = zeros(test_times, fft_size);   % 定点化计算结果和标准的比对

DCT_signal = zeros(test_times, dct_size);           % DCT变换完成后信号
sort_data  = zeros(sort_test_times, sort_size);           % 排序完成数据

num1 = zeros(test_times, mat_size);                 % 相乘的向量
num2 = zeros(test_times, mat_size);                 % 相乘的向量
product = zeros(test_times, 1);


%% 产生随机数据
for times = 1 : test_times
    % 生成DFT随机测试信号
    rand_num = 2 * rand(1, fft_size) - 1;
    real_signal(times, : ) = floor(rand_num * 2^5 + 0.5)/ 2^5;
    rand_num = 2 * rand(1, fft_size) - 1;
    imag_signal(times, : ) = floor(rand_num * 2^5 + 0.5) / 2^5;
    signal(times, : ) = real_signal(times, : ) + 1i * imag_signal(times, : );
    % 生成DCT随机测试信号
    rand_num = 2 * rand(1, dct_size) - 1;
    DCT_signal_original(times, :) = floor(rand_num * 2^5 + 0.5)/ 2^5;
    % 生成要进行内积的两个向量
    rand_num = 2 * rand(1, mat_size) - 1;
    num1(times, : ) = floor(rand_num * 2^6 + 0.5)/2^6;
    rand_num = 2 * rand(1, mat_size) - 1;
    num2(times, : ) = floor(rand_num * 2^6 + 0.5)/2^6;    
end

% 生成升序测试信号
rand_num = 2 * rand(1, sort_size) - 1;
for i = 1 : sort_test_times
    rand_num_sort = rand_num + i/2^12;
    sort_data_original(i,:) = floor(rand_num_sort * 2^15 + 0.5)/ 2^15;
end
%% DFT变换矩阵
dft_mat = dftmtx(fft_size);
dft_mat_real = real(dft_mat);
dft_mat_imag = imag(dft_mat);

%% 变换矩阵定点化
dft_mat_real = round(dft_mat_real * 2^7) / 2^7;
dft_mat_imag = round(dft_mat_imag * 2^7) / 2^7;
dft_mat = dft_mat_real + 1i * dft_mat_imag;

for i = 1 : test_times
    signal_fft(i,:) = signal(i,:) * dft_mat;%计算dft
    signal_fft_matlab(i,:) = fft(signal(i,:));%matlab标准结果
    signal_fft_compare(i,:)=abs(signal_fft(i,:)-signal_fft_matlab(i,:));%结果比对
end

MAE = mean(signal_fft_compare);
%% DCT变换矩阵及定点化
dct_mat = dctmtx(dct_size);
dct_mat = round(dct_mat * 2^7) / 2^7;
for i = 1 : test_times
    DCT_signal_temp = dct_mat * DCT_signal_original(i,:)';
    DCT_signal(i,:) = DCT_signal_temp';
end
%% 向量内积
for i = 1 : test_times
    product(i,1)= sum(num1(i,:) .* num2(i,:));
end
%% 排序计算
for i = 1 : sort_test_times
    sort_data(i,:) = sort(sort_data_original(i,:));
end
%% FFT结果打印
fprintf('\nDFT变换矩阵十进制结果（实部）：\n');
for u = 1 : fft_size
    for i = 1 : fft_size
        fprintf('%10f ', dft_mat_real(u,i));
    end
    fprintf('\n');
end

fprintf('\nDFT变换矩阵十进制结果（虚部）：\n');
for u = 1 : fft_size
    for i = 1 : fft_size
        fprintf('%10f ', dft_mat_imag(u,i));
    end
    fprintf('\n');
end

fprintf('\nDFT变换矩阵十六进制结果（实部）：\n');
for u = 1 : fft_size
    for i = 1 : fft_size
        temp = fi(dft_mat_real(u,i),1,16,7);
        fprintf('%s ', temp.hex);
    end
    fprintf('\n');
end

fprintf('\nDFT变换矩阵十六进制结果（虚部）：\n');
for u = 1 : fft_size
    for i = 1 : fft_size
        temp = fi(dft_mat_imag(u,i),1,16,7);
        fprintf('%s ', temp.hex);
    end
    fprintf('\n');
end

fprintf('\nFFT变换前十进制结果(实部)：\n');
for times = 1 : test_times
    fprintf('%10f ', real_signal(times, :));
    fprintf('\n');
end

fprintf('\nFFT变换前十进制结果(虚部)：\n');
for times = 1 : test_times
    fprintf('%10f ', imag_signal(times, :));
    fprintf('\n');
end

fprintf('\nFFT变换前十六进制结果（实部）：\n');
for times = 1 : test_times
    for i = 1 : fft_size
        temp = fi(real_signal(times,i),1,16,5);
        fprintf('%s ', temp.hex);
    end
    fprintf('\n');
end

fprintf('\nFFT变换前十六进制结果（虚部）：\n');
for times = 1 : test_times
    for i = 1 : fft_size
        temp = fi(imag_signal(times,i),1,16,5);
        fprintf('%s ', temp.hex);
    end
    fprintf('\n');
end

fprintf('\nFFT变换后十进制结果（实部）：\n');
for times = 1 : test_times
    fprintf('%10f ', real(signal_fft(times, :)));
    fprintf('\n');
end

fprintf('\nFFT变换后十进制结果（虚部）：\n');
for times = 1 : test_times
    fprintf('%10f ', imag(signal_fft(times, :)));
    fprintf('\n');
end

fprintf('\nFFT变换后matlab结果（实部）：\n');
for times = 1 : test_times
    fprintf('%10f ', real(signal_fft_matlab(times, :)));
    fprintf('\n');
end

fprintf('\nFFT变换后matlab结果（虚部）：\n');
for times = 1 : test_times
    fprintf('%10f ', imag(signal_fft_matlab(times, :)));
    fprintf('\n');
end

fprintf('\nFFT变换后十六进制结果（实部）：\n');
for times = 1 : test_times
    for i = 1 : fft_size
        temp = fi(real(signal_fft(times,i)),1,16,12);
        fprintf('%s ', temp.hex);
    end
    fprintf('\n');
end

fprintf('\nFFT变换后十六进制结果（虚部）：\n');
for times = 1 : test_times
    for i = 1 : fft_size
        temp = fi(imag(signal_fft(times,i)),1,16,12);
        fprintf('%s ', temp.hex);
    end
    fprintf('\n');
end

%% 向量内积结果打印
fprintf('\n内积前十进制结果：\n');
for times = 1 : test_times
    fprintf('%10f ', num1(times, :));
    fprintf('\n');
end

for times = 1 : test_times
    fprintf('%10f ', num2(times, :));
    fprintf('\n');
end

fprintf('\n内积前十六进制结果：\n');
for times = 1 : test_times
    for i = 1 : mat_size
        temp = fi(num1(times, i),1,16,6);
        fprintf('%s ', temp.hex);
    end
    fprintf('\n');
end

for times = 1 : test_times
    for i = 1 : mat_size
        temp = fi(num2(times, i),1,16,6);
        fprintf('%s ', temp.hex);
    end
    fprintf('\n');
end

fprintf('\n内积后十进制进制结果：\n');
for times = 1 : test_times
    fprintf('%16.12f ', product(times, 1));
    fprintf('\n');
end

fprintf('\n内积后十六进制结果：\n');
for times = 1 : test_times
    temp = fi(product(times, 1),1,16,12);
    fprintf('%s\n', temp.hex);
end

%% 打印FFT的测试数据文件
sel_print = 1;                  % 选择一组FFT数据打印
f1 = fopen('FFT_input.coe', 'w');
fprintf(f1, 'memory_initialization_radix = 16;\nmemory_initialization_vector = \n');
% FFT的输入的coe文件包含FFT的变换矩阵，实部为0-63，虚部为64-127
for u = 1 : fft_size
    for i = 1 : fft_size
        temp = fi(dft_mat_real(u,i),1,16,7);
        fprintf(f1, '%s,\n', temp.hex);
    end
end

for u = 1 : fft_size
    for i = 1 : fft_size
        temp = fi(dft_mat_imag(u,i),1,16,7);
        fprintf(f1, '%s,\n', temp.hex);
    end
end

% 变换矩阵后接着的为信号数据，实部为128-135，虚部为136-143
for i = 1 : fft_size
    temp = fi(real_signal(sel_print,i),1,16,5);
    fprintf(f1, '%s,\n', temp.hex);
end

for i = 1 : fft_size
    temp = fi(imag_signal(sel_print,i),1,16,5);
    fprintf(f1, '%s', temp.hex);
    if i == fft_size
        fprintf(f1, ';');
    else
        fprintf(f1, ',\n');
    end
end
fclose(f1);
%% 打印FFT结果数据
sel_print = 1;                  % 选择一组FFT数据打印
f1 = fopen('FFT_output.coe', 'w');
fprintf(f1, 'memory_initialization_radix = 16;\nmemory_initialization_vector = \n');
for i = 1 : fft_size
    temp = fi(real(signal_fft(sel_print,i)),1,16,12);
    fprintf(f1, '%s,\n', temp.hex);
end
for i = 1 : fft_size
    temp = fi(imag(signal_fft(sel_print,i)),1,16,12);
    if i ~= fft_size
        fprintf(f1, '%s,\n', temp.hex);
    else
        fprintf(f1, '%s;', temp.hex);
    end
end
fclose(f1);
%% 打印向量内积的测试数据文件
sel_print = 1;                  
f1 = fopen('product_input.coe', 'w');
fprintf(f1, 'memory_initialization_radix = 16;\nmemory_initialization_vector = \n');
%前16个为第一个向量的数据，后16个为第二个向量的数据
for i = 1 : mat_size
    temp = fi(num1(sel_print,i),1,16,6);
    fprintf(f1, '%s,\n', temp.hex);
end

for i = 1 : mat_size
    temp = fi(num2(sel_print,i),1,16,6);
    fprintf(f1, '%04s', temp.hex);
    if i == fft_size
        fprintf(f1, ';');
    else
        fprintf(f1, ',\n');
    end
end
fclose(f1);
%% 打印DCT变换的测试文件
sel_print = 1;                  % 选择一组DCT数据打印
f1 = fopen('DCT_input.coe', 'w');
fprintf(f1, 'memory_initialization_radix = 16;\nmemory_initialization_vector = \n');
for u = 1 : dct_size
    for i = 1 : dct_size
        temp = fi(dct_mat(u,i),1,16,7);
        fprintf(f1, '%s,\n', temp.hex);
    end
end
for u = 1 : dct_size
    for i = 1 : dct_size
        temp = fi(0,1,16,7);
        fprintf(f1, '%s,\n', temp.hex);
    end
end
for i = 1 : dct_size
    temp = fi(DCT_signal_original(sel_print,i),1,16,5);
    fprintf(f1, '%s,\n', temp.hex);
end
for i = 1 : dct_size
    temp = fi(0,1,16,5);
    fprintf(f1, '%s', temp.hex);
    if i == dct_size
        fprintf(f1, ';');
    else
        fprintf(f1, ',\n');
    end
end
fclose(f1);
%% 打印DCT输出文件
sel_print = 1;                  % 选择一组FFT数据打印
f1 = fopen('DCT_output.coe', 'w');
fprintf(f1, 'memory_initialization_radix = 16;\nmemory_initialization_vector = \n');
for i = 1 : dct_size
    temp = fi(DCT_signal(sel_print,i),1,16,12);
    fprintf(f1, '%s,\n', temp.hex);
end
for i = 1 : dct_size
    temp = fi(0,1,16,12);
    if i ~= dct_size
        fprintf(f1, '%s,\n', temp.hex);
    else
        fprintf(f1, '%s;', temp.hex);
    end
end
fclose(f1);
%% 打印排序的测试数据文件                 % 选择排序数据打印
f1 = fopen('sort_input.coe', 'w');
fprintf(f1, 'memory_initialization_radix = 16;\nmemory_initialization_vector = \n');
for i = 1 : sort_test_times
    for j = 1 : sort_size
        temp = fi(sort_data_original(i,j),1,16,15);
        if (i ~= sort_test_times) || (j ~= sort_size)
            fprintf(f1, '%s,\n', temp.hex);
        else 
            fprintf(f1, '%s;', temp.hex);
        end
    end
end
fclose(f1);
%% 打印排序输出文件                % 选择排序数据打印
f1 = fopen('sort_output.coe', 'w');
fprintf(f1, 'memory_initialization_radix = 16;\nmemory_initialization_vector = \n');
for i = 1 : sort_test_times
    for j = 1 : sort_size
        temp = fi(sort_data(i,j),1,16,15);
        if (i ~= sort_test_times) || (j ~= sort_size)
            fprintf(f1, '%s,\n', temp.hex);
        else 
            fprintf(f1, '%s;', temp.hex);
        end
    end
end
fclose(f1);