clear all; close all; clc;

start_char = 'B'; end_char = 'V';
exclude = [1,13,19, 26,30,40,55,59,67,71];
fprintf('=');
for i = 1:length(exclude)-1;
    fprintf('$%s$%d:$%s$%d,',start_char,exclude(i)+1,end_char,exclude(i+1)-1);
end
fprintf('\b\n');

