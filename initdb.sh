mongo battlerec --eval 'db.battles.remove({})'
mongo battlerec --eval 'db.pbattles.remove({})'
mongo battlerec --eval 'db.xp.remove({})'

mongoimport -d battlerec -c battles --type csv --file data.csv --headerline
