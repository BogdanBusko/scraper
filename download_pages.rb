require 'open-uri'
require 'nokogiri'
require 'json'

# Create structure of folders
Dir.mkdir('pages') if !File.exists?('pages')
Dir.mkdir('partners') if !File.exists?('partners')
Dir.mkdir('partners/images') if !File.exists?('partners/images')

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

# Scrap information about partner
partner_info = { partners: [] }

Dir['./partners/*.html'].each do |page|
  partner = {}
  data = Nokogiri::HTML(File.read(page)).css('div.PartnerDetail > div.media')

  img_html = data.css('div.media-discount-prev_image > a > img')
  if img_html.any?
    img_link = 'https://app.softserveinc.com' + img_html['src']
    begin
      img_name = File.basename(img_link)
      File.write("partners/images/#{img_name}", open(img_link, &:read))
    rescue URI::InvalidURIError
      img_name = nil
    end
  end

  partner[:title] = data.css('div.media_body > h2.media-discount-prev_title').text
  partner[:text] = data.css('div.media_body > p.media-discount-prev_text').text
  partner[:category] = data.css('div.media_body > p.category > span').text
  partner[:discount] = data.css('div.partner_right > div.media-discount-prev_disc').text
  partner[:location] = data.css('div.media_body > div.media-discount-prev_location > div')
    .map{ |location| location.css('span > a').text }
  partner[:image] = img_name
  partner_info[:partners] << partner
end

File.write('partners.json', partner_info.to_json)
