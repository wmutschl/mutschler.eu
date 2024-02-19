---
# An instance of the Contact widget.
widget: contact

# This file represents a page section.
headless: true

# Order that this section appears on the page.
weight: 130

title: Contact
subtitle:

content:
  # Automatically link email and phone or display as text?
  autolink: true

  # Email form provider
  #form:
  #  provider: netlify
  #  formspree:
  #    id:
  #  netlify:
  #    # Enable CAPTCHA challenge to reduce spam?
  #    captcha: false

  # Contact details (edit or remove options as required)
  email: willi@mutschler.eu
  phone: +49-7071-29-73140
  address:
    street: 'Eberhard-Karls-University Tübingen<br />School of Business and Economics<br />Department of International Macroeconomics and Finance<br />Mohlstr. 36'
    city: Tübingen
    region: BW
    postcode: 'D-72074'
    country: Germany
    country_code: DE
  coordinates:
    latitude: '48.52970222407578'
    longitude: '9.060530898768823'
  directions: 'Enter the building and go to the 7th floor. My office is number 416.'
#  office_hours:
#    - 'Monday 10:00 to 13:00'
#    - 'Wednesday 09:00 to 10:00'
  appointment_url: 'https://schedule.mutschler.eu'
  contact_links:
    - icon: twitter
      icon_pack: fab
      name: DM Me
      link: 'https://twitter.com/wmutschl'
#    - icon: skype
#      icon_pack: fab
#      name: Skype Me
#      link: 'skype:live:microsoft_18791?call'
#    - icon: video
#      icon_pack: fas
#      name: Zoom Me
#      link: 'https://zoom.com'

design:
  columns: '2'
---