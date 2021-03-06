# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

genre_hash = {
    "Advertisements" => "Advertisements",
    "Albums" => "Albums",
    "Art" => "Art",
    "Articles" => "Articles",
    "Awards" => "Awards",
    "Autobiographies" => "Autobiographies",
    "Bibliographies" => "Bibliographies",
    "Birth Certificates" => "Birth Certificates",
    "Books" => "Books",
    "Calendars" => "Calendars",
    "Cards" => "Cards",
    "Catalogs" => "Catalogs",
    "Charts" => "Charts",
    "Clippings" => "Clippings",
    "Correspondence" => "Correspondence",
    "Dictionaries" => "Dictionaries",
    "Diaries" => "Diaries",
    "Directories" => "Directories",
    "Documents" => "Documents",
    "Drama" => "Drama",
    "Drawings" => "Drawings",

    "Ephemera" => "Ephemera",
    "Encyclopedias" => "Encyclopedias",
    "Erotica" => "Erotica",
    "Essays" => "Essays",
    "Fiction" => "Fiction",
    "Finding Aids" => "Finding Aids",
    "Government Publications" => "Government Publications",
    "Government Records" => "Government Records",
    "Handbooks" => "Handbooks",
    "Leaflets" => "Leaflets",
    "Lecture Notes" => "Lecture Notes",
    "Legal Cases" => "Legal Cases",
    "Manuscripts" => "Manuscripts",
    "Maps" => "Maps",
    "Motion Pictures" => "Motion Pictures",
    "Musical Notation" => "Musical Notation",
    "Newsletters" => "Newsletters",
    "Newspapers" => "Newspapers",
    "Oral Histories" => "Oral Histories",
    "Paintings" => "Paintings",

    "Pamphlets" => "Pamphlets",
    "Periodicals" => "Periodicals",
    "Petitions" => "Petitions",
    "Photographs" => "Photographs",
    "Physical Objects" => "Physical Objects",
    "Poetry" => "Poetry",
    "Posters" => "Posters",
    "Press Releases" => "Press Releases",
    "Prints" => "Prints",
    "Programs" => "Programs",
    "Records" => "Records",
    "Reviews" => "Reviews",
    "Sound Recordings" => "Sound Recordings",
    "Speeches" => "Speeches",
    "Surveys" => "Surveys",
    "Theses" => "Theses",
    "Transcriptions" => "Transcriptions",
    "Websites" => "Websites",
    "Yearbooks" => "Yearbooks"
}
if Genre.count == 0
  genre_hash.each do |key, val|
    Genre.create(label: val)
  end
end

resource_types = {
    "Artifact" => "http://id.loc.gov/vocabulary/resourceTypes/art",
    "Audio" => "http://id.loc.gov/vocabulary/resourceTypes/aud",
    "Cartographic" => "http://id.loc.gov/vocabulary/resourceTypes/car",
    "Collection" => "http://id.loc.gov/vocabulary/resourceTypes/col",
    "Dataset" => "http://id.loc.gov/vocabulary/resourceTypes/dat",
    "Digital [indicates born­digital]" => "http://id.loc.gov/vocabulary/resourceTypes/dig",
    "Manuscript" => "http://id.loc.gov/vocabulary/resourceTypes/man",
    "Mixed material" => "http://id.loc.gov/vocabulary/resourceTypes/mix",
    "Moving image" => "http://id.loc.gov/vocabulary/resourceTypes/mov",
    "Multimedia" => "http://id.loc.gov/vocabulary/resourceTypes/mul",
    "Notated music" => "http://id.loc.gov/vocabulary/resourceTypes/not",
    "Still Image" => "http://id.loc.gov/vocabulary/resourceTypes/img",
    "Tactile" => "http://id.loc.gov/vocabulary/resourceTypes/tac",
    "Text" => "http://id.loc.gov/vocabulary/resourceTypes/txt",
    "Unspecified" => "http://id.loc.gov/vocabulary/resourceTypes/unk"
}
if ResourceType.count == 0
  resource_types.each do |key, val|
    ResourceType.create(label: key, uri: val)
  end
end

cc_licenses = {
    'Contact host institution for more information' => 'Contact host institution for more information',
    'No known restrictions on use' => 'No known restrictions on use',
    'All rights reserved' => 'All rights reserved'
}
if Rights.count == 0
  cc_licenses.each do |key, val|
    Rights.create(label: key)
  end
end

if Carousel.count == 0
  @carousel = []
  @carousel << {collection_pid: "b5644r52v",
                image_pid: 'n296wz15f',
                title: "Kewpie Photographs",
                iiif: "/downloads/n296wz15f?file=carousel",
                description: "Kewpie was part of a queer community of people who were known amongst themselves and by the wider community in Cape Town as ‘moffies.' These photographs document Kewpie’s life in District Six, Cape Town, South Africa between 1950 and 1993."}


  @carousel << {collection_pid: "5999n337h",
                image_pid: 'fx719m50n',
                title: "Alison Laing's Photographs",
                #iiif: "https://repository.digitaltransgenderarchive.net:8182/iiif/2/#{GenericObject.find_by(pid: 'fx719m50n').iiif_id}/square/full/0/default.jpg",
                #iiif: "http://localhost:3000/downloads/fx719m50n?file=carousel",
                iiif: "/downloads/fx719m50n?file=carousel",
                description: "These photographs, primarily taken by unknown photographers with a few taken by Mariette Pathy Allen, document Alison Laing speaking, performing, and interacting with others at various events such as Fantasia Fairs and IFGE Houston. They feature a variety of trans activists, including Dottie Laing, Dallas Denny, Ariadne Kane, JoAnn Roberts, and Virginia Prince. This collection also includes professional portraits of Alison and Dottie Laing."}
  @carousel << {collection_pid: "g158bh328",
                image_pid: 'w9505051c',
                title: "Phyllis Frye Collection",
                #iiif: "https://repository.digitaltransgenderarchive.net:8182/iiif/2/#{GenericObject.find_by(pid: 'w9505051c').iiif_id}/full/,760/0/default.jpg",
                #iiif: "https://repository.digitaltransgenderarchive.net:8182/iiif/2/#{GenericObject.find_by(pid: 'w9505051c').iiif_id}/square/full/0/default.jpg",
                iiif: "/downloads/w9505051c?file=carousel",
                description: "Phyllis Randolph Frye is the first openly transgender judge in the United States. She is also a US Army veteran, a licensed engineer, an attorney, and a prominent trans activist. Photographs in this collection include 11 photographs and 1 certificate from the US Army, documents her life journey between 1962 and 2006. It reflects her life before transitioning as well as her important role in the movement for transgender rights."}
  @carousel << {collection_pid: "4m90dv65c",
                image_pid: '44558d50p',
                title: "Berg and Høeg Photographs",
                #iiif: "https://repository.digitaltransgenderarchive.net:8182/iiif/2/#{GenericObject.find_by(pid: '44558d50p').iiif_id}/full/,760/0/default.jpg",
                #iiif: "https://repository.digitaltransgenderarchive.net:8182/iiif/2/#{GenericObject.find_by(pid: '44558d50p').iiif_id}/square/full/0/default.jpg",
                iiif: "/downloads/44558d50p?file=carousel",
                description: "Marie Høeg (1866-1949) and Bolette Berg (1872-1944) were Norwegian photographers from Horton, Norway. Marie, the more outgoing of the two, was an active women's rights advocate who also enjoyed crossdressing in private. A private collection of photographs form the Berg and Høeg photography studio primarily shows Marie, with occasional appearances of Bolette, crossdressing in various fashions. These photographs show Marie's willingness to digress from and contradict social norms."}

  @carousel << {collection_pid: "k0698759z",
                image_pid: 'sq87bt68c',
                title: "Informational and Event Brochures",
                iiif: "/downloads/sq87bt68c?file=carousel",
                description: "This diverse collection includes provides information about many different trans-related topics, including activist and social organizations."}

  @carousel.each do |c|
    Carousel.create(collection_pid: c[:collection_pid], image_pid: c[:image_pid], title: c[:title], iiif: c[:iiif], description: c[:description])
  end
end
