function scrpt_analyze_corona

close all;

str_data_to_plot = 'total_deaths'; %   'total_deaths'   'total_cases'

% get the list of countries
list_cntrs_1st_wave = {'China', 'South Korea', 'Japan', 'Iran'};
list_cntrs_2nd_wave = {'Italy', 'Spain', 'France', 'Germany'};
list_cntrs_3rd_wave = {'United Kingdom', 'Israel', 'United States', 'Australia'};
list_cntrs_forgotten = {'Austria', 'Belgium', 'Netherlands', 'Denmark'};
list_cntrs_east_europe = {'Poland', 'Belarus', 'Czech Republic', 'Romania'};
list_list_countries_to_plot = {...
    list_cntrs_1st_wave, ...
    list_cntrs_2nd_wave, ...
    list_cntrs_3rd_wave, ...
    list_cntrs_forgotten, ...
    list_cntrs_east_europe};

% load information from csv table
[crn_txt, crn_data] = import_current_corona_status();
[pop_txt, pop_data] = import_population_data();

% just for manual searching
list_countries_all = get_list_countries(crn_txt);

for idx = 1: length(list_list_countries_to_plot)
    list_countries_to_plot = list_list_countries_to_plot{idx};
    % plot a graph for a specific list of countries
    plot_graph_list_of_countries(...
        crn_txt, crn_data, pop_txt, pop_data, list_countries_to_plot, str_data_to_plot);
end

end


function [textdata, data] = import_current_corona_status()

tmp = importdata('table_corona.csv');
textdata = tmp.textdata;
data = tmp.data;

end


function [textdata, data] = import_population_data()

load('table_population.mat', 'textdata', 'data');

end



function plot_graph_list_of_countries(...
    crn_txt, crn_data, pop_txt, pop_data, list_countries_to_plot, str_data_to_plot)

% determine which column to used, i.e., which data to plot
idx_data_to_plot = str_to_idx_data_to_plot(str_data_to_plot);

% allocate variables
n_countries = length(list_countries_to_plot);
data_all = cell(1, n_countries);
dates_all = cell(1, n_countries);
pop_all = zeros(1, n_countries);

for idx = 1: length(list_countries_to_plot)
    % get the data for this country
    str_country = list_countries_to_plot{idx};
    [data_idx, dates] = filter_data_by_country(str_country, crn_txt, crn_data);
    % collect the data to arrays
    data_all{idx} = data_idx(:, idx_data_to_plot);
    dates_all{idx} = dates;
    % find the total population of this country
    idx_pop_country = find(strcmp(pop_txt(:, 3), str_country)) - 1;
    pop_all(idx) = pop_data(idx_pop_country, end);
end

% plot the data
plot_all(dates_all, data_all, pop_all, list_countries_to_plot, str_data_to_plot);

end


function [data_country, dates] = filter_data_by_country(str_country, textdata, data)

idxs = strcmp(textdata(:, 2), str_country);
dates = textdata(idxs, 1);
data_country = data(idxs, :);

end


function plot_all(dates_all, data_all, pop_all, list_countries_to_plot, str_data_to_plot)

n_vectors = length(dates_all);
fig = figure('name', strrep(str_data_to_plot, '_', ' '), ...
    'Position', [50,50,900,900]);
idxs_min_val = 1e6 * ones(1, n_vectors);
hold on;
for idx = 1: n_vectors
    % get the corona data to plot
    dates = datenum(dates_all{idx});    
    data_norm = data_all{idx} / (1e3 * pop_all(idx));
    data_norm = 10 * log10(data_norm);
    min_ratio_to_display = get_min_ratio_to_display(str_data_to_plot);
    idx_tmp = find(data_norm > min_ratio_to_display, 1);
    if ~isempty(idx_tmp), idxs_min_val(idx) = idx_tmp; end
    plot(dates, data_norm, 'linewidth', 2)
end

date_first = dates(min(idxs_min_val));
date_last = dates(end);
set_plot_parameters(list_countries_to_plot, date_first, date_last, str_data_to_plot);

filename_fig = cell2mat(list_countries_to_plot);
filename_fig = strrep(filename_fig, ' ', '');
filename_fig = [filename_fig, '.png'];
saveas(fig, filename_fig);

end


function set_plot_parameters(...
    list_countries_to_plot, date_first, date_last, str_data_to_plot)

datetick('x','mmm-dd');
vector_magnitude_db = get_vector_magnitude_db(str_data_to_plot);
vector_magnitude = 10 .^ (-vector_magnitude_db ./ 10);
yticks(vector_magnitude_db);
yticklabels(vector_magnitude);
grid minor;
legend(list_countries_to_plot);
ylabel({'sick ratio'; '[one sick per...]'});
xlim([date_first, date_last - 1]);
ylim([vector_magnitude_db(1), vector_magnitude_db(end)]);
set(gca, 'fontsize', 14);
set(gca, 'fontname', 'times');

end


function [list_countries, list_dates] = get_list_countries(textdata)
list_countries = unique(textdata(2: end, 2));
list_dates = unique(textdata(2: end, 1));
end


function min_ratio_to_display = get_min_ratio_to_display(str_data_to_plot)
if strcmp(str_data_to_plot, 'total_cases'), min_ratio_to_display = -60;
elseif strcmp(str_data_to_plot, 'total_deaths'), min_ratio_to_display = -80; 
else, disp(['data to plot not found in table! str_data_to_plot = ',...
    str_data_to_plot]);
end
end


function idx_data_to_plot = str_to_idx_data_to_plot(str_data_to_plot)
if strcmp(str_data_to_plot, 'total_cases'), idx_data_to_plot = 3;
elseif strcmp(str_data_to_plot, 'total_deaths'), idx_data_to_plot = 4;
else, disp(['data to plot not found in table! str_data_to_plot = ',...
    str_data_to_plot]);
end
end

function vector_magnitude_db = get_vector_magnitude_db(str_data_to_plot)
if strcmp(str_data_to_plot, 'total_cases'), vector_magnitude_db = -60: 10: -20;
elseif strcmp(str_data_to_plot, 'total_deaths'), vector_magnitude_db = -80:10:-30;
else, disp(['data to plot not found in table! str_data_to_plot = ',...
    str_data_to_plot]);
end

end