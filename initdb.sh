mongo battlerec --eval 'db.battles.remove({})'
mongo battlerec --eval 'db.pbattles.remove({})'

mongoimport -d battlerec -c battles --type csv --file data.csv --headerline
