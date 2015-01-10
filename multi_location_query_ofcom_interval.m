function [response , delay , error] =  multi_location_query_ofcom_interval...
    ( latitude_start, latitude_end, longitude_start,...
    longitude_end ,num_of_steps, distance_divider, my_path,orientation,...
    semiMajorAxis,SemiMinorAxis,start_freq,stop_freq,height,heightType)
% multi_location_query_ofcom_interval queries the Ofcom white space
% database poactively (multi locations in one request)
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

error=false; %Default error value
delay=[]; %Default delay value
request_type = '"AVAIL_SPECTRUM_REQ"';
server_name='https://tvwsdb.broadbandappstestbed.com/json.rpc';
text_coding='"Content-Type: application/json "';

%%
query_generator_interval...
    (request_type,latitude_start,latitude_end ,...
    longitude_start, longitude_end ,num_of_steps,distance_divider, my_path,orientation,...
    semiMajorAxis,SemiMinorAxis,start_freq,stop_freq,height,heightType);
%%
cmnd=['/usr/bin/curl -X POST ',server_name,' -H ',text_coding,' --data-binary @',my_path,'/ofcom.json -w %{time_total}'];
[status,response]=system(cmnd);

%check for error
err = findstr('error' , response);
if ~isempty(err)
    error = true;
end

%     remove_first_extra_error_lines = findstr(response,'[');
%     response = response((remove_first_extra_error_lines(1)):end);
%     disp(response)

pos_end_query_str=findstr(response,']');
delay=str2num(response((pos_end_query_str(end)+1):end));

system('rm ofcom.json');

end

function  query_generator_interval(request_type,latitude_start,latitude_end ,...
    longitude_start, longitude_end ,num_of_steps,distance_divider, my_path,orientation,...
    semiMajorAxis,SemiMinorAxis,start_freq,stop_freq,height,heightType)
%This function will generate the json array requests along a line between
%two points

% Dividing the distance into segmets to be queried gradually

longitude = linspace(longitude_start,longitude_end , distance_divider);
latitude = linspace(latitude_start,latitude_end , distance_divider);

% This is need it in order to dynamically add  and remove the comma to
% separate json object correctly
if num_of_steps > 1
    comma = ',';
else
    comma = '';
end

cd(my_path);
%To start the json array
dlmwrite('ofcom.json','[','delimiter','');

for i = 1:num_of_steps
    if i == num_of_steps
        comma='';
    end
    request=['{"jsonrpc": "2.0",',...
        '"method": "spectrum.paws.getSpectrum",',...
        '"params": {',...
        '"type": ',request_type,', ',...
        '"version": "0.6", ',...
        '"deviceDesc": ',...
        '{ "manufacturerId": "TuDelft", ',...
        '"modelId": "Test", ',...
        '"serialNumber": "0001", ',...
        '"etsiEnDeviceType": "A", ',...
        '"etsiEnDeviceEmissionsClass": "3", ',...
        '"etsiEnDeviceCategory": "master", ',...
        '"etsiEnTechnologyId": "466", '...
        '"rulesetIds": [ "OfcomWhiteSpacePilotV1-2013",],}, ',...
        '"location": ',...
        '{ "point": ',...
        '{ "center": ',...
        '{"latitude": ',num2str(latitude(i)),', '...
        '"longitude": ',num2str(longitude(i)),',}, ',...
        '"orientation": ',num2str(orientation),', ' ,...
        '"semiMajorAxis": ',num2str(semiMajorAxis),', ' ,...
        '"semiMinorAxis": ',num2str(SemiMinorAxis),', ' ,...
        '},}, ',...
        '"capabilities": { ',...
        '"frequencyRanges": [ {' ,...
        '"startHz": ',num2str(start_freq),', ',...
        '"stopHz": ',num2str(stop_freq),', ',...
        '},],},',...
        '"antenna": { ',...
        '"height":',num2str(height),', ',...
        '"heightType":',heightType,'}, ',...
        '},"id": "123456789"}',comma];
    
    dlmwrite('ofcom.json',request,'-append','delimiter','');
end
%close the json array
dlmwrite('ofcom.json',']','-append','delimiter','');
end
