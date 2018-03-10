Sequel.migration do
  change do
    create_table(:codes, :ignore_index_errors=>true) do
      primary_key :id
      Integer :level_id, :null=>false
      String :code, :null=>false
      Integer :bonus, :default=>0
      TrueClass :main, :default=>true, :null=>false
      String :hint, :text=>true
      String :title, :text=>true
      String :note, :text=>true
      Integer :number
      String :sektor, :default=>"Локация", :text=>true, :null=>false
      String :ko, :default=>"х.з.", :size=>64, :null=>false
      
      index [:id], :name=>:codes_id_uindex, :unique=>true
    end
    
    create_table(:gamelog, :ignore_index_errors=>true) do
      primary_key :id
      DateTime :ts, :null=>false
      Integer :game_id, :null=>false
      Integer :level_id
      Integer :team_id
      Integer :user_id
      Integer :code_id
      String :input, :text=>true
      String :action, :size=>50
      String :msg, :text=>true
      TrueClass :valid, :default=>false, :null=>false
      
      index [:id], :name=>:gamelog_id_uindex, :unique=>true
    end
    
    create_table(:games, :ignore_index_errors=>true) do
      primary_key :id
      String :title, :text=>true, :null=>false
      String :anounce, :text=>true, :null=>false
      DateTime :start, :null=>false
      DateTime :stop, :null=>false
      Integer :team_id
      TrueClass :closed, :default=>false, :null=>false
      
      index [:id], :name=>:games_id_uindex, :unique=>true
    end
    
    create_table(:hints, :ignore_index_errors=>true) do
      primary_key :id
      Integer :level_id, :null=>false
      String :title, :text=>true
      String :text, :text=>true
      Integer :timer, :default=>600
      
      index [:id], :name=>:hints_id_uindex, :unique=>true
    end
    
    create_table(:status, :ignore_index_errors=>true) do
      primary_key :id
      Integer :game_id, :null=>false
      Integer :team_id, :null=>false
      Integer :level_id, :null=>false
      DateTime :enter
      DateTime :spoiler
      Integer :pause_time, :default=>0
      DateTime :pause_at
      DateTime :end
      Integer :bonus, :default=>0
      Integer :penalty, :default=>0
      
      index [:id], :name=>:status_id_uindex, :unique=>true
    end
    
    create_table(:teams, :ignore_index_errors=>true) do
      primary_key :id
      String :title, :text=>true, :null=>false
      Integer :active_game
      
      index [:id], :name=>:teams_id_uindex, :unique=>true
      index [:title], :name=>:teams_title_uindex, :unique=>true
    end
    
    create_table(:users, :ignore_index_errors=>true) do
      primary_key :id
      String :login, :text=>true, :null=>false
      String :password, :default=>"", :text=>true, :null=>false
      Integer :team_id
      TrueClass :captain, :default=>false, :null=>false
      TrueClass :team_adopt, :default=>false, :null=>false
      TrueClass :admin, :default=>false, :null=>false
      String :title, :default=>"Чупакабра", :text=>true, :null=>false
      String :theme, :default=>"default", :size=>32, :null=>false
      Integer :tgid
      
      index [:id], :name=>:users_id_uindex, :unique=>true
      index [:login], :name=>:users_login_uindex, :unique=>true
    end
    
    create_table(:files, :ignore_index_errors=>true) do
      primary_key :id
      String :name, :text=>true, :null=>false
      String :path, :text=>true, :null=>false
      foreign_key :game_id, :games, :null=>false, :key=>[:id]
      
      index [:id], :name=>:files_id_uindex, :unique=>true
    end
    
    create_table(:game_reg, :ignore_index_errors=>true) do
      primary_key :id
      foreign_key :team_id, :teams, :null=>false, :key=>[:id]
      foreign_key :game_id, :games, :null=>false, :key=>[:id]
      TrueClass :adopt, :default=>true, :null=>false
      
      index [:id], :name=>:game_reg_id_uindex, :unique=>true
      index [:team_id, :game_id], :name=>:game_reg_team_id_game_id_uindex, :unique=>true
    end
    
    create_table(:gameowner, :ignore_index_errors=>true) do
      primary_key :id
      foreign_key :game_id, :games, :null=>false, :key=>[:id]
      foreign_key :user_id, :users, :null=>false, :key=>[:id]
      
      index [:game_id]
      index [:id], :name=>:gameowner_id_uindex, :unique=>true
      index [:user_id]
    end
    
    create_table(:levels, :ignore_index_errors=>true) do
      primary_key :id
      foreign_key :game_id, :games, :null=>false, :key=>[:id]
      String :title, :text=>true, :null=>false
      Integer :number
      Integer :sequence
      String :type, :default=>"standart", :size=>30
      String :question, :text=>true
      String :spoiler, :text=>true
      String :answer
      Integer :duration, :default=>3600
      Integer :need_codes, :default=>0, :null=>false
      Integer :penalty, :default=>0, :null=>false
      TrueClass :hide_title, :default=>false, :null=>false
      Integer :code_hint_timer, :default=>0, :null=>false
      
      index [:id], :name=>:levels_id_uindex, :unique=>true
    end
  end
end
