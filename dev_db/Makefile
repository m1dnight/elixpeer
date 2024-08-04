fresh: 
	docker compose down
	rm -rf data
	mkdir data 
	mkdir data/database_backup 
	mkdir data/database_archive
	mkdir data/pg_data_dir
	docker compose create 
	docker compose up -d 

base_backup: 
	docker compose exec db bash -c "PGUSER=postgres pg_basebackup -D /database_backup"

snapshot: 
	@test $(name) || (echo "name is not set" ; exit 1)
	psql -h localhost -U postgres postgres -c "SELECT pg_create_restore_point('$(name)');"

restore: 
	@test $(name) || (echo "name is not set" ; exit 1)
	@echo "restoring snapshot $(name)"
	@docker compose down 
	@mv data/pg_data_dir/pg_wal pg_wal_backup

# remove the data dir for postgres
	@rm -rf data/pg_data_dir 
	@mkdir data/pg_data_dir

# copy the database backup to the data dir
	@cp -a data/database_backup/. data/pg_data_dir/.

# remove the wal files from the base backup, they're outdated
	@rm -rf data/pg_data_dir/pg_wal 

# copy back the wal files back  
	@mv  pg_wal_backup data/pg_data_dir/pg_wal

# set the recovery signal 
	@sed -i "s/recovery_target_name='.*'/recovery_target_name='$(name)'/g" postgres.conf
	@touch data/pg_data_dir/recovery.signal
	@docker compose up -d 


promote: 
	psql -h localhost -U postgres postgres -c "SELECT pg_wal_replay_resume();"


