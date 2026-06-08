import 'package:flutter/foundation.dart';

/// The Volcano Codex — real-world volcano entries unlocked one at a time as the
/// player summits peaks. This gives the app genuine informational content
/// beyond the core timing game.
@immutable
class CodexEntry {
  const CodexEntry({
    required this.id,
    required this.name,
    required this.location,
    required this.elevation,
    required this.lastEruption,
    required this.type,
    required this.fact,
  });

  final String id;
  final String name;
  final String location;
  final String elevation; // metres, human-readable
  final String lastEruption;
  final String type;
  final String fact;
}

class Codex {
  Codex._();

  static const List<CodexEntry> all = [
    CodexEntry(
      id: 'c0',
      name: 'Mount Vesuvius',
      location: 'Campania, Italy',
      elevation: '1,281 m',
      lastEruption: '1944',
      type: 'Somma-stratovolcano',
      fact:
          'Its 79 AD eruption buried Pompeii and Herculaneum under metres of '
          'ash, preserving the Roman cities almost intact for archaeologists.',
    ),
    CodexEntry(
      id: 'c1',
      name: 'Mount Etna',
      location: 'Sicily, Italy',
      elevation: '3,357 m',
      lastEruption: 'Ongoing',
      type: 'Stratovolcano',
      fact:
          'Europe\u2019s most active volcano. Its eruptions have been '
          'documented for over 2,700 years \u2014 one of the longest records '
          'on Earth.',
    ),
    CodexEntry(
      id: 'c2',
      name: 'Krakatoa',
      location: 'Sunda Strait, Indonesia',
      elevation: '813 m',
      lastEruption: '2020',
      type: 'Caldera',
      fact:
          'The 1883 eruption was heard nearly 5,000 km away and is considered '
          'one of the loudest sounds in recorded history.',
    ),
    CodexEntry(
      id: 'c3',
      name: 'Mount Fuji',
      location: 'Honshu, Japan',
      elevation: '3,776 m',
      lastEruption: '1707',
      type: 'Stratovolcano',
      fact:
          'Japan\u2019s highest peak and a sacred symbol. Its near-perfect '
          'symmetrical cone formed over hundreds of thousands of years.',
    ),
    CodexEntry(
      id: 'c4',
      name: 'K\u012blauea',
      location: 'Hawai\u02bbi, USA',
      elevation: '1,247 m',
      lastEruption: 'Ongoing',
      type: 'Shield volcano',
      fact:
          'One of the world\u2019s most active volcanoes. Its fluid lava '
          'flows have continuously reshaped the Big Island for decades.',
    ),
    CodexEntry(
      id: 'c5',
      name: 'Mount St. Helens',
      location: 'Washington, USA',
      elevation: '2,549 m',
      lastEruption: '2008',
      type: 'Stratovolcano',
      fact:
          'Its 1980 eruption blew away the entire north face, reducing the '
          'summit by about 400 metres in minutes.',
    ),
    CodexEntry(
      id: 'c6',
      name: 'Eyjafjallaj\u00f6kull',
      location: 'Iceland',
      elevation: '1,651 m',
      lastEruption: '2010',
      type: 'Stratovolcano',
      fact:
          'The 2010 ash cloud grounded European air travel for days \u2014 the '
          'largest airspace shutdown since World War II.',
    ),
    CodexEntry(
      id: 'c7',
      name: 'Mauna Loa',
      location: 'Hawai\u02bbi, USA',
      elevation: '4,169 m',
      lastEruption: '2022',
      type: 'Shield volcano',
      fact:
          'The largest active volcano on Earth by volume \u2014 measured from '
          'its base on the sea floor, it is taller than Mount Everest.',
    ),
    CodexEntry(
      id: 'c8',
      name: 'Mount Pinatubo',
      location: 'Luzon, Philippines',
      elevation: '1,486 m',
      lastEruption: '1993',
      type: 'Stratovolcano',
      fact:
          'Its 1991 eruption ejected so much ash and gas that global '
          'temperatures dropped by about 0.5\u00b0C for over a year.',
    ),
    CodexEntry(
      id: 'c9',
      name: 'Cotopaxi',
      location: 'Andes, Ecuador',
      elevation: '5,897 m',
      lastEruption: '2016',
      type: 'Stratovolcano',
      fact:
          'One of the highest active volcanoes in the world, crowned by a '
          'glacier despite sitting almost directly on the equator.',
    ),
    CodexEntry(
      id: 'c10',
      name: 'Nyiragongo',
      location: 'DR Congo',
      elevation: '3,470 m',
      lastEruption: '2021',
      type: 'Stratovolcano',
      fact:
          'Holds one of the largest lava lakes on Earth. Its lava is unusually '
          'fluid and can flow at speeds of up to 60 km/h.',
    ),
    CodexEntry(
      id: 'c11',
      name: 'Yellowstone Caldera',
      location: 'Wyoming, USA',
      elevation: '2,805 m',
      lastEruption: '~70,000 yrs ago',
      type: 'Supervolcano',
      fact:
          'A supervolcano whose magma chamber powers the park\u2019s geysers '
          'and hot springs, including the famous Old Faithful.',
    ),
  ];

  static CodexEntry byId(String id) => all.firstWhere((c) => c.id == id);
}
