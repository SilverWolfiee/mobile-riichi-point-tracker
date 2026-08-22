enum YakuSpecial { none, nagashiMangan, yakuman, doubleYakuman }

class YakuEntry {
  final String id;
  final String name;
  final int han;
  final bool closedOnly;
  final YakuSpecial special;

  const YakuEntry({
    required this.id,
    required this.name,
    required this.han,
    this.closedOnly = false,
    this.special = YakuSpecial.none,
  });
  bool get isYakuman =>
      special == YakuSpecial.yakuman || special == YakuSpecial.doubleYakuman;
}

const List<YakuEntry> allYaku = [
  //1 han
  YakuEntry(id: 'riichi', name: 'Riichi (Ready Hand)', han: 1, closedOnly: true),
  YakuEntry(id: 'ippatsu', name: 'Ippatsu (One-Shot)', han: 1, closedOnly: true),
  YakuEntry(id: 'menzen_tsumo', name: 'Menzen Tsumo (Fully Concealed Hand)', han: 1, closedOnly: true),
  YakuEntry(id: 'pinfu', name: 'Pinfu (All Sequences)', han: 1, closedOnly: true),
  YakuEntry(id: 'tanyao', name: 'Tanyao (All Simples)', han: 1),
  YakuEntry(id: 'iipeiko', name: 'Iipeiko (Pure Double Sequence)', han: 1, closedOnly: true),
  YakuEntry(id: 'yakuhai_haku', name: 'Yakuhai: White Dragon (Value Tiles: White)', han: 1),
  YakuEntry(id: 'yakuhai_hatsu', name: 'Yakuhai: Green Dragon (Value Tiles: Green)', han: 1),
  YakuEntry(id: 'yakuhai_chun', name: 'Yakuhai: Red Dragon (Value Tiles: Red)', han: 1),
  YakuEntry(id: 'yakuhai_seat', name: 'Yakuhai: Seat Wind (Value Tiles: Seat Wind)', han: 1),
  YakuEntry(id: 'yakuhai_round', name: 'Yakuhai: Round Wind (Value Tiles: Prevalent Wind)', han: 1),
  YakuEntry(id: 'chanta_open', name: 'Chanta [Open] (Terminal & Honor in Each Set)', han: 1),
  YakuEntry(id: 'sanshoku_open', name: 'Sanshoku Doujun [Open] (Three Mixed Sequences)', han: 1),
  YakuEntry(id: 'ittsu_open', name: 'Ittsu [Open] (Pure Straight)', han: 1),

  //2 han
  YakuEntry(id: 'chanta_closed', name: 'Chanta [Closed] (Terminal & Honor in Each Set)', han: 2),
  YakuEntry(id: 'sanshoku_closed', name: 'Sanshoku Doujun [Closed] (Three Mixed Sequences)', han: 2),
  YakuEntry(id: 'ittsu_closed', name: 'Ittsu [Closed] (Pure Straight)', han: 2),
  YakuEntry(id: 'toitoi', name: 'Toitoi (All Triplets)', han: 2),
  YakuEntry(id: 'sanankou', name: 'Sanankou (Three Concealed Triplets)', han: 2),
  YakuEntry(id: 'sankantsu', name: 'Sankantsu (Three Quads)', han: 2),
  YakuEntry(id: 'chiitoitsu', name: 'Chiitoitsu (Seven Pairs)', han: 2, closedOnly: true),
  YakuEntry(id: 'honroutou', name: 'Honroutou (All Terminals & Honors)', han: 2),
  YakuEntry(id: 'shousangen', name: 'Shousangen (Little Three Dragons)', han: 2),
  YakuEntry(id: 'junchan_open', name: 'Junchan [Open] (Terminal in Each Set)', han: 2),
  YakuEntry(id: 'honitsu_open', name: 'Honitsu [Open] (Half Flush)', han: 2),

  //3 han
  YakuEntry(id: 'junchan_closed', name: 'Junchan [Closed] (Terminal in Each Set)', han: 3),
  YakuEntry(id: 'honitsu_closed', name: 'Honitsu [Closed] (Half Flush)', han: 3),
  YakuEntry(id: 'ryanpeikou', name: 'Ryanpeikou (Twice Pure Double Sequence)', han: 3, closedOnly: true),

  //5/6 han
  YakuEntry(id: 'chinitsu_open', name: 'Chinitsu [Open] (Full Flush)', han: 5),
  YakuEntry(id: 'chinitsu_closed', name: 'Chinitsu [Closed] (Full Flush)', han: 6),

  //special
  YakuEntry(
    id: 'nagashi_mangan',
    name: 'Nagashi Mangan (Mangan at Draw / All Terminals & Honors Discarded)',
    han: 5,
    special: YakuSpecial.nagashiMangan,
  ),

  //yakuman (13 han)
  YakuEntry(
    id: 'kokushi',
    name: 'Kokushi Musou (Thirteen Orphans)',
    han: 13,
    special: YakuSpecial.yakuman,
    closedOnly: true,
  ),
  YakuEntry(
    id: 'suuankou',
    name: 'Suuankou (Four Concealed Triplets)',
    han: 13,
    special: YakuSpecial.yakuman,
    closedOnly: true,
  ),
  YakuEntry(
    id: 'daisangen',
    name: 'Daisangen (Big Three Dragons)',
    han: 13,
    special: YakuSpecial.yakuman,
  ),
  YakuEntry(
    id: 'shousuushii',
    name: 'Shousuushii (Little Four Winds)',
    han: 13,
    special: YakuSpecial.yakuman,
  ),
  YakuEntry(
    id: 'daisuushii',
    name: 'Daisuushii (Big Four Winds)',
    han: 13,
    special: YakuSpecial.yakuman,
  ),
  YakuEntry(
    id: 'tsuuiisou',
    name: 'Tsuuiisou (All Honors)',
    han: 13,
    special: YakuSpecial.yakuman,
  ),
  YakuEntry(
    id: 'chinroutou',
    name: 'Chinroutou (All Terminals)',
    han: 13,
    special: YakuSpecial.yakuman,
  ),
  YakuEntry(
    id: 'ryuuiisou',
    name: 'Ryuuiisou (All Green)',
    han: 13,
    special: YakuSpecial.yakuman,
  ),
  YakuEntry(
    id: 'chuuren',
    name: 'Chuuren Poutou (Nine Gates)',
    han: 13,
    special: YakuSpecial.yakuman,
    closedOnly: true,
  ),
  YakuEntry(
    id: 'suukantsu',
    name: 'Suukantsu (Four Quads)',
    han: 13,
    special: YakuSpecial.yakuman,
  ),
  YakuEntry(
    id: 'tenhou',
    name: 'Tenhou (Heavenly Hand / Blessing of Heaven)',
    han: 13,
    special: YakuSpecial.yakuman,
    closedOnly: true,
  ),
  YakuEntry(
    id: 'chiihou',
    name: 'Chiihou (Earthly Hand / Blessing of Earth)',
    han: 13,
    special: YakuSpecial.yakuman,
    closedOnly: true,
  ),

  //double yakuman (26 han)
  YakuEntry(
    id: 'kokushi_13wait',
    name: 'Kokushi Musou Juusanmen Machi (Thirteen Orphans 13-Sided Wait)',
    han: 26,
    special: YakuSpecial.doubleYakuman,
    closedOnly: true,
  ),
  YakuEntry(
    id: 'suuankou_tanki',
    name: 'Suuankou Tanki (Four Concealed Triplets Single Wait)',
    han: 26,
    special: YakuSpecial.doubleYakuman,
    closedOnly: true,
  ),
  YakuEntry(
    id: 'chuuren_9wait',
    name: 'Chuuren Poutou Kyuumen Machi (Pure Nine Gates 9-Sided Wait)',
    han: 26,
    special: YakuSpecial.doubleYakuman,
    closedOnly: true,
  ),
  YakuEntry(
    id: 'daisuushi_double',
    name: 'Daisuushii (Big Four Winds - Double Yakuman Rule)',
    han: 26,
    special: YakuSpecial.doubleYakuman,
  ),
];