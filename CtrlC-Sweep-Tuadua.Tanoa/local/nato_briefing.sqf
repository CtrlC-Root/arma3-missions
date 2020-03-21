// https://community.bistudio.com/wiki/Arma_3_Briefing

CC__scenario_nato_brief_situation = [
  "A local Syndikat operative was captured and provided intelligence concerning",
  "an illegal weapons shipment his cell had received. Using aerial and sattelite",
  "surveillance we've tracked the Syndikat cell to a village on Taudau Island.",
  "We cannot allow illegal militias to operate in Tanoa unchallenged and we",
  "definitely cannot allow the Syndikat to arm themselves further."
] joinString " ";

CC__scenario_nato_brief_kilo = [
  "Transport <marker name='markerNatoKilo'>Kilo</marker> will provide transport for",
  "insertion into and exfiltration out of Taudau Island for assault team",
  "<execute expression='diaryTeamViper call CC__scenario_diaryLink'>Viper</execute>."
] joinString " ";

CC__scenario_nato_brief_viper = [
  "Assault team Viper will conduct recon and direct action operations."
] joinString " ";

CC__scenario_nato_brief_mission = [
  "Transport",
  "<execute expression='diaryTeamKilo call CC__scenario_diaryLink'>Kilo</execute>",
  "will insert",
  "<execute expression='diaryTeamViper call CC__scenario_diaryLink'>Viper</execute>",
  "into Taudau Island <marker name='markerNatoInsert'>here</marker> and return to",
  "<marker name='markerNatoFob'>base</marker> to remain on standby. Assault team Viper",
  "will move to and sweep the <marker name='markerNatoSweep'>village</marker> to",
  "locate the weapons and destroy them. Transport Kilo will exfil Viper from Taudau",
  "Island <marker name='markerNatoExfil'>here</marker> and return to base."
] joinString " ";

CC__scenario_nato_briefing = [
  ["diarySituation", "Situation", CC__scenario_nato_brief_situation],
  ["diaryTeamKilo", "Team Kilo", CC__scenario_nato_brief_kilo],
  ["diaryTeamViper", "Team Viper", CC__scenario_nato_brief_viper],
  ["diaryMission", "Mission", CC__scenario_nato_brief_mission]
];
