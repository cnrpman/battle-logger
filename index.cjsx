fs = require 'fs-extra'
path_ex = require 'path-extra'

{_, SERVER_HOSTNAME} = window
ROOT = __dirname
## ## Predef Seg ## ##

## ## Status Seg ## ##
after_battle       = false
deck_main_id       = -1
deck_subfleet_id   = -1
deck_support_id    = -1
battle_package     = {}

status_init = ()->
  after_battle       = false
  deck_main_id       = -1
  deck_subfleet_id   = -1
  deck_support_id    = -1
  battle_package     = {}

## ## Listener ## ##
window.addEventListener 'game.response', (e) ->
## ## Functions ## ##
  {method, path, body, postBody} = e.detail
  {_ships, _decks, _slotitems} = window

  ## get dat from poi ##
  get_decks_from_poi = (deck_main_id,deck_support_id,deck_subfleet_id) ->
    get_item = (item_id,onslot) ->
      item = _slotitems[item_id]
      package_item =
        id:     item.api_slotitem_id
        star:   item.api_level
        onslot: onslot
    get_ship = (ship_id) ->
      ship = _ships[ship_id]
      package_ship =
        charId:      ship.api_ship_id
        entityId:    ship.api_id
        lvl:         ship.api_lv
        cond:        ship.api_cond
        hp:          ship.api_nowhp
        firepower:   ship.api_karyoku[0]
        torpedo:     ship.api_raisou[0]
        antiair:     ship.api_taiku[0]
        armor:       ship.api_soukou[0]
        luck:        ship.api_lucky[0]
        fuel:        ship.api_fuel
        bull:        ship.api_bull
        items:       (get_item item_id,ship.api_onslot[i] for item_id,i in ship.api_slot when item_id isnt -1)
    get_deck = (deck_id) ->
      if deck_id is -1
        return undefined
      package_deck = (get_ship ship_id for ship_id in _decks[deck_id].api_ship when ship_id isnt -1)

    package_decks =
      kcdata_api_ship_sally_deck: get_deck deck_main_id
      kcdata_api_ship_support_deck: get_deck deck_support_id
      kcdata_api_ship_subfleet_deck: get_deck deck_subfleet_id

  get_item_decks_from_poi = (deck_main_id) ->
    get_item = (item_id,onslot) ->
      item = _slotitems[item_id]
      package_item =
        id:     item.api_slotitem_id
        star:   item.api_level
        onslot: onslot
    get_ship = (ship_id) ->
      ship = _ships[ship_id]
      package_ship =
        charId:      ship.api_ship_id
        entityId:    ship.api_id
        items:       (get_item item_id,ship.api_onslot[i] for item_id,i in ship.api_slot when item_id isnt -1)
    get_deck = (deck_id) ->
      if deck_id is -1
        return undefined
      package_deck = (get_ship ship_id for ship_id in _decks[deck_id].api_ship when ship_id isnt -1)

    package_decks =
      kcdata_api_ship_sally_deck: get_deck deck_main_id
    ## get dat from post ##

## ## Logics ## ##
  switch path
    when '/kcsapi/api_req_sortie/battle','/kcsapi/api_req_sortie/airbattle'#只有日战/航空战有支援
      after_battle = true
      deck_main_id = body.api_dock_id - 1 #讲个笑话，娇喘的英语

      switch body.api_support_flag
        when 0
          deck_support_id = -1
        when 1
          deck_support_id = body.api_support_info.api_support_airatack.api_deck_id - 1
        when 2,3
          deck_support_id = body.api_support_info.api_support_hourai.api_deck_id - 1

      array = path.match /\/kcsapi\/(.*)\/(.*)/
      battle_package[array[1]+'_'+array[2]] = body

    when '/kcsapi/api_req_battle_midnight/battle','/kcsapi/api_req_battle_midnight/sp_midnight'
      after_battle = true
      deck_main_id = body.api_deck_id - 1

      array = path.match /\/kcsapi\/(.*)\/(.*)/
      battle_package[array[1]+'_'+array[2]] = body

    when '/kcsapi/api_req_sortie/battleresult'
      battle_package.kcdata_api_deck_at_pre_battle = get_decks_from_poi deck_main_id,deck_support_id,deck_subfleet_id

    when '/kcsapi/api_port/port','/kcsapi/api_get_member/ship_deck'#拿载机量,然后保存
      if after_battle
        battle_package.kcdata_api_deck_at_post_battle = get_item_decks_from_poi deck_main_id
        battle_package.datetime = (new Date()).valueOf()

        console.log battle_package
        fs.writeFileSync path_ex.join(ROOT,battle_package.datetime+'.json'),JSON.stringify(battle_package)

        status_init()

module.exports =
  name: 'BattleLogger'
  author: [<a key={0} href=""></a>]
  displayName: [<FontAwesome key={0} name='pie-chart' />, ' 战斗记录']
  description: '战斗过程记录'
  show: false
  version: '0.0'
