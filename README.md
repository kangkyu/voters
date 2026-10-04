# Voters app: Ruby on Rails version 7.0

- Many users submit scores at the same time
- Save all to the database
- user, like, contestant
- Screen should show "my votes" for the user. That would be a list of contestants with their "vote" the user selected. The user should be able to select and update the "vote" of each contestant
- the "total votes" screen is on the separate page for current running result of total scores from all users of all contestant. It can be accessed only by admin.
- I want it to be a Rails app with hotwire
- I might try google cloud platform this time?

Scenario to build
- add postgresql to persist
- add logic and show on web pages
- use broadcast (No need to refresh screen)
- separate front and back for mobile apps?
- add authentication for voters/users
- add authorization for admins - to see vote results

More Features
- admin able to add users and assign admin
- only allowed users able to see the results
