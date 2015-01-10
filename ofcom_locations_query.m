% This script output/plot the delay and delay destribtion of the response time of querying Ofcom WSDB.
%   Last update: 10 January 2015

% Reference:
%   P. Pawelczak et al. (2014), "Will Dynamic Spectrum Access Drain my
%   Battery?," submitted for publication.

%   Code development: Amjed Yousef Majid (amjadyousefmajid@student.tudelft.nl),
%                     Przemyslaw Pawelczak (p.pawelczak@tudelft.nl)

% Copyright (c) 2014, Embedded Software Group, Delft University of
% Technology, The Netherlands. All rights reserved.
%
% Redistribution and use in source and binary forms, with or without
% modification, are permitted provided that the following conditions
% are met:
%
% 1. Redistributions of source code must retain the above copyright notice,
% this list of conditions and the following disclaimer.
%
% 2. Redistributions in binary form must reproduce the above copyright
% notice, this list of conditions and the following disclaimer in the
% documentation and/or other materials provided with the distribution.
%
% 3. Neither the name of the copyright holder nor the names of its
% contributors may be used to endorse or promote products derived from this
% software without specific prior written permission.
%
% THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
% "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
% LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
% PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
% HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
% SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
% TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
% PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
% LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
% NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
% SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
tic;
clear;
close all;
clc;
%%
%Path to save files (select your own)
my_path='/home/amjed/Documents/Gproject/workspace/data/WSDB_DATA';
% Query params
request_type='"AVAIL_SPECTRUM_REQ"';
orientation= 45;
semiMajorAxis = 50;
SemiMinorAxis = 50;
start_freq = 470000000;
stop_freq = 790000000;
height=7.5;
heightType = '"AGL"';
%%
num_of_steps = [1 2 4 8 16 32  64 128 256];
distance_divider =  num_of_steps(length(num_of_steps));
num_of_query_per_location = 20;
%%
%The data stored in the file as longitude latitude longitude latitude
format long;
long_lat_ofcom = load('long_lat_ofcom.txt');
[r ,c] = size(long_lat_ofcom);
delay_ofcom_vec = [];

for k=1:r
    %Location data
    long_start= long_lat_ofcom(k , 1)
    lat_start=long_lat_ofcom(k , 2)
    long_end=long_lat_ofcom(k , 3)
    lat_end=long_lat_ofcom(k , 4)
    
    %collect the delay
    delay_temp=[];
    delay_ofcom=[];
    for i = 1:length(num_of_steps)
        for j = 1:num_of_query_per_location
            instant_clock=clock; %Start clock again if scanning only one database
            %disp(['key_counter' ,num2str(key_counter)]) % for debugging
            cd(my_path);
            
            [msg_ofcom,delay_ofcom_tmp,error_ofcom_tmp]=...
                multi_location_query_ofcom_interval(...
                lat_start ,lat_end ,long_start,long_end,num_of_steps(i) , distance_divider , my_path,orientation,...
                semiMajorAxis,SemiMinorAxis,start_freq,stop_freq,height,heightType );
            
            % writing the response to a file
            if error_ofcom_tmp==0
                delay_temp = [delay_temp  delay_ofcom_tmp];
                raw_delay(i,j) = delay_ofcom_tmp;
                var_name_txt=(['ofcom_',num2str( num_of_steps(i) ),'_',datestr(instant_clock, 'DD_mmm_YYYY_HH_MM_SS'),'_',num2str(j)]);
                dlmwrite([var_name_txt,'.txt'],msg_ofcom,'');
            end
        end
        %Get the average of the delay of the same queried area
        delay = sum(delay_temp)/length(delay_temp);
        %collecting the averaged delay
        delay_ofcom = [delay_ofcom delay];
        delay_temp = [] ;
        delay = [] ;
    end
    %%
    hold on
    plot(num_of_steps , delay_ofcom , '-*', 'LineWidth' , 1);
    xlabel('Number of locations per one request');
    ylabel('Delay (sec)');
    delay_ofcom_vec = [delay_ofcom_vec delay_ofcom];
    delay_ofcom = []; % reset required for the next step
end
legend('10km')%,'10km','10km','50km','across US')
for i=1:length(num_of_steps)
    plot(num_of_steps(i) , raw_delay(i,:), 'r*');
end
hold off
%%
['Elapsed time: ',num2str(toc/60),' min']