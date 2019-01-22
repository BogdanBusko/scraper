require 'open-uri'
require 'nokogiri'
require 'json'

# Create structure of folders
Dir.mkdir('pages') if !File.exists?('pages')
Dir.mkdir('partners') if !File.exists?('partners')
Dir.mkdir('partners/images') if !File.exists?('partners/images')

=begin
# Downloan page first page
url = 'https://app.softserveinc.com/discount/en/partner/'
File.write('./pages/partner.html', open(url, &:read))

# Get count of pages
COUNT_OF_PAGES = Nokogiri::HTML(File.read('./pages/partner.html')).
  css('div#PartnerList > ul.btn-items a.btn')[2].text.split(' ').last.to_i

# Download pages with partners information
COUNT_OF_PAGES.times do |i|
  print "Pages download #{i + 1} of #{COUNT_OF_PAGES}\r"
  File.write("./pages/page-#{i + 1}.html", open("#{url}page-#{i + 1}", &:read))
end

puts "Pages downloaded #{COUNT_OF_PAGES} of #{COUNT_OF_PAGES}"

# Get partner show page url
urls = []
count = 0

Dir['./pages/page-*.html'].each do |page|
  Nokogiri::HTML(File.read(page)).
      css("div#PartnerList > div.media > div.media_left > div.media-discount_image > a").each do |link|
    count += 1
    print "#{count} of partner pages found...\r"
    urls << link['href']
  end
end

puts "#{count} of partner pages found..."

# Download partner page
urls.each_with_index do |page_url, index|
  print "Pages download #{index} of #{urls.count}\r"
  File.write("./partners/#{page_url.split('/').last}.html", open(URI.parse(URI.encode("https://app.softserveinc.com#{page_url}".strip)), &:read))
end

puts "Pages downloaded #{urls.count}\t\t"

# Download partners logo
url = 'https://app.softserveinc.com'

Dir['./partners/*.html'].each do |page|
  image = Nokogiri::HTML(File.read(page)).css('div.PartnerDetail > div.media > div.media_left > div.media-discount-prev_image > a > img')

  unless image.empty?
    extension = File.extname(image.attr('src'))
    filename = File.basename(page, '.html')

    File.write("./partners/images/#{filename}#{extension}", open(URI.parse(URI.encode(url + image.attr('src'))), &:read))
  end
end
=end

# Scrap information about partner
partner_info = { partners: [] }

Dir['./partners/*.html'].each do |page|
  partner = {}
  data = Nokogiri::HTML(File.read(page)).css('div.PartnerDetail > div.media')

  partner[:title] = data.css('div.media_body > h2.media-discount-prev_title').text
  partner[:description] = data.css('div.media_body > p.media-discount-prev_text').text.gsub("\r", "\n")
  short_description = partner[:description][0..69].gsub("\n", "")
  partner[:short_description] = short_description + (partner[:description].length > 70 ? '...' : '')
  partner[:category] = data.css('div.media_body > p.category > span').text
  partner[:discount] = data.css('div.partner_right > div.media-discount-prev_disc').text
  partner[:location] = data.css('div.media_body > div.media-discount-prev_location > div')
    .map do |location|
      data = {}
      coordinates_hash = {}
      location_hash = {}

      data[:sity] = location.css('span > a').text
      js_script = location.css('script').text.gsub("\n", "").gsub(' ', '').gsub("\"", "")
      coordinates = js_script.split('markers.push(pointdata);')
      coordinates[0][/{(.*?)}/m].gsub('{', '').gsub('}', '').split(',').each do |data|
        coordinates_hash[data.split(':')[0].to_sym] = data.split(':')[1]
      end

      coordinates[1][/{(.*?)}/m].gsub('{', '').gsub('}', '').split(',').each do |data|
        location_hash[data.split(':')[0].to_sym] = data.split(':')[1]
      end

      data[:map_coordinates] = coordinates_hash
      data[:map_location] = location_hash
      data
  end
  partner_info[:partners] << partner
end

File.write('partners.json', partner_info.to_json)

