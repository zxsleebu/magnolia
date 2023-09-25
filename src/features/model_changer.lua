local win32 = require("libs.win32")
local ffi = require("libs.protected_ffi")
local cbs = require("libs.callbacks")
local errors = require("libs.error_handler")
require("libs.types")

local list = {
    {"Local T Agent", "tm_phoenix"},
    {"Local CT Agent", "ctm_sas"},
    {"Blackwolf | Sabre", "tm_balkan_variantj"},
    {"Rezan The Ready | Sabre", "tm_balkan_variantg"},
    {"Maximus | Sabre", "tm_balkan_varianti"},
    {"Dragomir | Sabre", "tm_balkan_variantf"},
    {"Lt. Commander Ricksaw | NSWC SEAL", "ctm_st6_varianti"},
    {"'Two Times' McCoy | USAF TACP", "ctm_st6_variantm"},
    {"Buckshot | NSWC SEAL", "ctm_st6_variantg"},
    {"Seal Team 6 Soldier | NSWC SEAL", "ctm_st6_variante"},
    {"3rd Commando Company | KSK", "ctm_st6_variantk"},
    {"'The Doctor' Romanov | Sabre", "tm_balkan_varianth"},
    {"Michael Syfers  | FBI Sniper", "ctm_fbi_varianth"},
    {"Markus Delrow | FBI HRT", "ctm_fbi_variantg"},
    {"Operator | FBI SWAT", "ctm_fbi_variantf"},
    {"Slingshot | Phoenix", "tm_phoenix_variantg"},
    {"Enforcer | Phoenix", "tm_phoenix_variantf"},
    {"Soldier | Phoenix", "tm_phoenix_varianth"},
    {"The Elite Mr. Muhlik | Elite Crew", "tm_leet_variantf"},
    {"Prof. Shahmat | Elite Crew", "tm_leet_varianti"},
    {"Osiris | Elite Crew", "tm_leet_varianth"},
    {"Ground Rebel | Elite Crew", "tm_leet_variantg"},
    {"Special Agent Ava | FBI", "ctm_fbi_variantb"},
    {"B Squadron Officer | SAS", "ctm_sas_variantf"},
    {"Anarchist", "tm_anarchist"},
    {"Anarchist (A)", "tm_anarchist_varianta"},
    {"Anarchist (B)", "tm_anarchist_variantb"},
    {"Anarchist (C)", "tm_anarchist_variantc"},
    {"Anarchist (D)", "tm_anarchist_variantd"},
    {"Pirate", "tm_pirate"},
    {"Pirate (A)", "tm_pirate_varianta"},
    {"Pirate (B)", "tm_pirate_variantb"},
    {"Pirate (C)", "tm_pirate_variantc"},
    {"Pirate (D)", "tm_pirate_variantd"},
    {"Professional", "tm_professional"},
    {"Professional (1)", "tm_professional_var1"},
    {"Professional (2)", "tm_professional_var2"},
    {"Professional (3)", "tm_professional_var3"},
    {"Professional (4)", "tm_professional_var4"},
    {"Separatist", "tm_separatist"},
    {"Separatist (A)", "tm_separatist_varianta"},
    {"Separatist (B)", "tm_separatist_variantb"},
    {"Separatist (C)", "tm_separatist_variantc"},
    {"Separatist (D)", "tm_separatist_variantd"},
    {"GIGN", "ctm_gign"},
    {"GIGN (A)", "ctm_gign_varianta"},
    {"GIGN (B)", "ctm_gign_variantb"},
    {"GIGN (C)", "ctm_gign_variantc"},
    {"GIGN (D)", "ctm_gign_variantd"},
    {"GSG-9", "ctm_gsg9"},
    {"GSG-9 (A)", "ctm_gsg9_varianta"},
    {"GSG-9 (B)", "ctm_gsg9_variantb"},
    {"GSG-9 (C)", "ctm_gsg9_variantc"},
    {"GSG-9 (D)", "ctm_gsg9_variantd"},
    {"IDF", "ctm_idf"},
    {"IDF (B)", "ctm_idf_variantb"},
    {"IDF (C)", "ctm_idf_variantc"},
    {"IDF (D)", "ctm_idf_variantd"},
    {"IDF (E)", "ctm_idf_variante"},
    {"IDF (F)", "ctm_idf_variantf"},
    {"SWAT", "ctm_swat"},
    {"SWAT (A)", "ctm_swat_varianta"},
    {"SWAT (B)", "ctm_swat_variantb"},
    {"SWAT (C)", "ctm_swat_variantc"},
    {"SWAT (D)", "ctm_swat_variantd"},
    {"SAS", "ctm_sas_varianta"},
    {"ST6", "ctm_st6"},
    {"ST6 (A)", "ctm_st6_varianta"},
    {"ST6 (B)", "ctm_st6_variantb"},
    {"ST6 (C)", "ctm_st6_variantc"},
    {"ST6 (D)", "ctm_st6_variantd"},
    {"Balkan (E)", "tm_balkan_variante"},
    {"Balkan (A)", "tm_balkan_varianta"},
    {"Balkan (B)", "tm_balkan_variantb"},
    {"Balkan (C)", "tm_balkan_variantc"},
    {"Balkan (D)", "tm_balkan_variantd"},
    {"Jumpsuit (A)", "tm_jumpsuit_varianta"},
    {"Jumpsuit (B)", "tm_jumpsuit_variantb"},
    {"Jumpsuit (C)", "tm_jumpsuit_variantc"},
    {"Phoenix Heavy", "tm_phoenix_heavy"},
    {"Heavy", "ctm_heavy"},
    {"Leet (A)", "tm_leet_varianta"},
    {"Leet (B)", "tm_leet_variantb"},
    {"Leet (C)", "tm_leet_variantc"},
    {"Leet (D)", "tm_leet_variantd"},
    {"Leet (E)", "tm_leet_variante"},
    {"Phoenix", "tm_phoenix"},
    {"Phoenix (A)", "tm_phoenix_varianta"},
    {"Phoenix (B)", "tm_phoenix_variantb"},
    {"Phoenix (C)", "tm_phoenix_variantc"},
    {"Phoenix (D)", "tm_phoenix_variantd"},
    {"FBI", "ctm_fbi"},
    {"FBI (A)", "ctm_fbi_varianta"},
    {"FBI (C)", "ctm_fbi_variantc"},
    {"FBI (D)", "ctm_fbi_variantd"},
    {"FBI (E)", "ctm_fbi_variante"},
}
for i = 1, #list do
    list[i][2] = "legacy/" .. list[i][2]
end
local custom_models_path_relative = "models/player/custom_player/"
local custom_models_path = "csgo/" .. custom_models_path_relative
local ext = ".mdl"
local custom_model_dirs = win32.dir(custom_models_path, false, ext, true)
if not custom_model_dirs then
    gui.label("No custom models found")
    return
end
local is_allowed = function(name, param)
    return not name:find("_" .. param) and not name:find(param .. "_")
end
for i = #custom_model_dirs, 1, -1 do
    local name = custom_model_dirs[i]:sub(1, -#ext-1)
    if is_allowed(name, "arms")
    and is_allowed(name, "emote")
    and is_allowed(name, "bone")
    and not name:find("anims") then
        table.insert(list, 1, {name, name})
    end
end
local name_index_list = {}
local model_names = {}
for i = 1, #list do
    local name = list[i][1]
    if #name > 31 then
        --get last 31 characters
        name = "..." .. name:sub(-28)
    end
    list[i][1] = name
    model_names[i] = name
    name_index_list[name] = i
end
-- if not el:value() then return end
-- local lp = entitylist.get_local_player()
-- if not lp then return end
-- local ct_model = ct_agent:val_index()
-- local t_model = t_agent:val_index()
-- if ct_model < 0 and t_model < 0 then return end
-- local ct_model_name = list[ct_model][2]
-- local t_model_name = list[t_model][2]
-- local ct_model_path = custom_models_path_relative .. ct_model_name .. ext
-- local t_model_path = custom_models_path_relative .. t_model_name .. ext
-- local teamnum = lp.m_iTeamNum
-- local model_path
-- if teamnum == 2 then
--     model_path = t_model_path
-- elseif teamnum == 3 then
--     model_path = ct_model_path
-- end
-- if not model_path then return end
-- lp:set_model(model_path)
local ct_agent, t_agent
local custom_model = gui.checkbox("Custom model"):options(function (el)
    gui.label("You can use down and up arrow keys to change")
    gui.label("All default models are in the bottom")
    ct_agent = gui.dropdown("CT agent", model_names)
    -- local ct_agent_textinput = menu.add_text_input("ct_agent_textinput", "ct_agent_textinput", "")
    -- ct_agent_textinput:set_visible(false)
    t_agent = gui.dropdown("T agent", model_names)
    -- local t_agent_textinput = ui.add_text_input("t_agent_textinput", "t_agent_textinput", "")
    -- t_agent_textinput:set_visible(false)
    -- cbs.frame_stage(function()
    --     if not ui.is_visible() then return end
    --     local ct_agent_value, t_agent_value = ct_agent_textinput:get_value(), t_agent_textinput:get_value()
    --     if name_index_list[ct_agent_value] then
    --         local val = name_index_list[ct_agent_value] - 1
    --         if val ~= ct_agent:val_index() then
    --             ct_agent.el:set_value(val)
    --         end
    --     end
    --     if name_index_list[t_agent_value] then
    --         local val = name_index_list[t_agent_value] - 1
    --         if val ~= t_agent:val_index() then
    --             t_agent.el:set_value(val)
    --         end
    --     end
    -- end)
    -- delay.add(function()
    --     ct_agent:update(function(el)
    --         ct_agent_textinput:set(el:value())
    --     end)
    --     t_agent:update(function(el)
    --         t_agent_textinput:set(el:value())
    --     end)
    -- end, 300)

end):update(function(el)
    if not el:value() then
        local sv_cheats_old_value = cvars.sv_cheats:get_bool()
        cvars.sv_cheats:set_bool(true)
        engine.execute_client_cmd("cl_fullupdate")
        cvars.sv_cheats:set_bool(sv_cheats_old_value)
    end
end)

cbs.frame_stage(function(stage)
    if stage ~= 4 then return end
    if not custom_model:value() then return end
    local lp = entitylist.get_local_player()
    if not lp or not lp:is_alive()  then return end
    local ct_model = ct_agent:val_index()
    local t_model = t_agent:val_index()
    if ct_model < 0 and t_model < 0 then return end
    local ct_model_name = list[ct_model][2]
    local t_model_name = list[t_model][2]
    local ct_model_path = custom_models_path_relative .. ct_model_name .. ext
    local t_model_path = custom_models_path_relative .. t_model_name .. ext
    local teamnum = lp.m_iTeamNum
    local model_path
    if teamnum == 2 then
        model_path = t_model_path
    elseif teamnum == 3 then
        model_path = ct_model_path
    end
    if not model_path then return end
    lp:set_model(model_path)
end)
