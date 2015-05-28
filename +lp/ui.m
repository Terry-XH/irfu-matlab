classdef ui < handle
	%LP.UI User interface to +lp package
	%   LP.UI(spacecraft,probe,plasma,parameters)
	properties (SetAccess = protected)
		SpacecraftList % Nr 1 is always user defined
		spacecraftUsed
		ProbeList % Nr 1 is always user defined  
		probeUsed % 1..N from ProbeList
		ProbeSurfaceList % Nr 1 is always user defined  
		probeSurfaceUsed % 1..N from ProbeSurfaceList
		PlasmaList
		plasmaUsed
		figHandle
		Axes     % top,bottom,infotext
		UserData % user data
		InputParameters =struct('factorUV',1,'rSunAU',1,...
			'vectorUString','-5:0.2:40','vectorU',-5:0.2:40,'biasCurrent',0) 
		Output
	end
	methods
		function obj = ui(varargin)
			%% Check input
			args=varargin;
			while ~isempty(args)
				if isa(args{1},'lp.spacecraft'),
					obj.SpacecraftList = args{1};
					args(1) =[];
				elseif isa(args{1},'lp.lprobe'),
					obj.ProbeList = args{1};
					args(1) =[];
				elseif isa(args{1},'lp.plasma')
					obj.PlasmaList = args{1};
					args(1) =[];
				else
					error('lp.ui input unknown!');
				end
			end
			if ~isa(obj.SpacecraftList,'lp.spacecraft'),
				obj.SpacecraftList = lp.default_spacecraft;
			end
			if ~isa(obj.ProbeList,'lp.probe'),
				obj.ProbeList = lp.default_lprobe;
			end
			if ~isa(obj.PlasmaList,'lp.plasma'),
				obj.PlasmaList = lp.default_plasma;
			end
			obj.SpacecraftList = [obj.SpacecraftList(1) obj.SpacecraftList];
			obj.SpacecraftList(1).name = 'user defined';
			obj.ProbeList = [obj.ProbeList(1) obj.ProbeList];
			obj.ProbeList(1).name = 'user defined';
			obj.PlasmaList = [obj.PlasmaList(1) obj.PlasmaList];
			obj.PlasmaList(1).name = 'user defined';
			obj.ProbeSurfaceList = [{'user defined'} lp.photocurrent];
			
			%% Initialize IDE
			obj.new_ide();
			obj.spacecraftUsed = 2;
			obj.probeUsed = 2;
			obj.plasmaUsed = 2;
			obj.set_plasma_model(obj.plasmaUsed);
			obj.set_probe_type(  obj.probeUsed);
		end
		function new_ide(obj)
			%% initialize figure
			set(0,'defaultLineLineWidth', 1.5);
			figH=figure;
			obj.figHandle=figH;
			clf reset;
			clear h;
			set(figH,'color','white'); % white background for figures (default is grey)
			set(figH,'PaperUnits','centimeters')
			set(figH,'defaultAxesFontSize',14);
			set(figH,'defaultTextFontSize',14);
			set(figH,'defaultAxesFontUnits','pixels');
			set(figH,'defaultTextFontUnits','pixels');
			xSize = 13; ySize = 16;
			xLeft = (21-xSize)/2; yTop = (30-ySize)/2;
			set(figH,'PaperPosition',[xLeft yTop xSize ySize])
			set(figH,'Position',[100 300 xSize*50 ySize*50])
			set(figH,'paperpositionmode','auto') % to get the same printing as on screen
			clear xSize sLeft ySize yTop
			%        set(fn,    'windowbuttondownfcn', 'irf_minvar_gui(''ax'')');zoom off;
			obj.Axes.bottom = axes('position',[0.1 0.3 0.5 0.3]); % [x y dx dy]
			obj.Axes.top    = axes('position',[0.1 0.67 0.5 0.3]); % [x y dx dy]
			linkaxes([obj.Axes.top obj.Axes.bottom],'x');
		
			obj.Axes.infotext = axes('position',[0.1 0.0 0.5 0.13]); % [x y dx dy]
			axis(obj.Axes.infotext,'off');
			obj.Axes.infoTextHandle = text(0,1,'','parent',obj.Axes.infotext);
			%% initialize probe menu
			colPanelBg = [1 0.95 1];
			hp         = uipanel('Title','Probe','FontSize',12,'BackgroundColor',colPanelBg,'Position',[.7 .0 .3 .39]);
			uiPar      = {'Parent',hp,'backgroundcolor',colPanelBg,'style','text'};
			popupProbeTxt        = obj.popup_list(obj.ProbeList);
			popupProbeSurfaceTxt = obj.popup_list(obj.ProbeSurfaceList);
			inp.probe.type.text                 = uicontrol(uiPar{:},'String','type','style','text',   'Position',[0   230 60   20]);
			inp.probe.type.value                = uicontrol(uiPar{:},'String',popupProbeTxt,           'Position',[60  230 130  20],'style','popup','Callback',@(src,evt)obj.set_probe_type(src,evt));
			inp.probe.surface.text              = uicontrol(uiPar{:},'String','surface',               'Position',[0   210 60   20]);
			inp.probe.surface.value             = uicontrol(uiPar{:},'String',popupProbeSurfaceTxt,    'Position',[60  210 130  20],'style','popup','Callback',@(src,evt)obj.set_probe_surface(src,evt));
			inp.probe.areaTotalVsSunlit.text    = uicontrol(uiPar{:},'String','total/sunlit area',     'Position',[0   190 120 20],'style','text');
			inp.probe.areaTotalVsSunlit.value   = uicontrol(uiPar{:},'String','',                      'Position',[120 190 70  20]);
			inp.probe.radiusSphere.text         = uicontrol(uiPar{:},'String','sphere radius [cm]',    'Position',[0   170 120 20]);
			inp.probe.radiusSphere.value        = uicontrol(uiPar{:},'String','','style','edit',       'Position',[120 170 70  20],'backgroundcolor','white','Callback',@(src,evt)obj.get_probe_radius_sphere);
			inp.probe.radiusSphere.SIconversion = 1e-2;
			inp.probe.lengthWire.text           = uicontrol(uiPar{:},'String','cyl/wire length [cm]',  'Position',[0   150 120 20]);
			inp.probe.lengthWire.value          = uicontrol(uiPar{:},'String','','style','edit',       'Position',[120 150 70  20],'backgroundcolor','white','Callback',@(src,evt)obj.get_probe_length_wire);
			inp.probe.lengthWire.SIconversion   = 1e-2;
			inp.probe.radiusWire.text           = uicontrol(uiPar{:},'String','cyl/wire radius [cm]',  'Position',[0   130 120 20]);
			inp.probe.radiusWire.value          = uicontrol(uiPar{:},'String','',                      'Position',[120 130 70  20],'style','edit','backgroundcolor','white','Callback',@(src,evt)obj.get_probe_radius_wire);
			inp.probe.radiusWire.SIconversion   = 1e-2;
			inp.probe.biasCurrent.text          = uicontrol(uiPar{:},'String','bias current [uA]',     'Position',[0   110 120 20]);
			inp.probe.biasCurrent.value         = uicontrol(uiPar{:},'String','0','style','edit',      'Position',[120 110 70  20],'backgroundcolor','white','Callback',@(src,evt)obj.get_probe_bias);
			inp.probe.biasCurrent.SIconversion  = 1e-6;
			%% initialize parameters menu
			inp.factorUvText                   = uicontrol('Parent',hp,'String','UV factor',             'Position',[0   70 60 20]);
			inp.factorUvValue                  = uicontrol('Parent',hp,'String',num2str(obj.InputParameters.factorUV),'Position',[70  70 100 20],'style','edit','backgroundcolor','white','Callback',@(src,evt)obj.get_factor_uv);
			inp.rSunText                       = uicontrol('Parent',hp,'String','Rsun [AU]',             'Position',[0   50 60 20]);
			inp.rSunValue                      = uicontrol('Parent',hp,'String',num2str(obj.InputParameters.rSunAU),              'Position',[70  50 100 20],'style','edit','backgroundcolor','white','Callback',@(src,evt)obj.get_distance_to_sun_au);
			inp.vectorUText                    = uicontrol('Parent',hp,'String','U [V]',                 'Position',[0   30 60 20]);
			inp.vectorUValue                   = uicontrol('Parent',hp,'String',num2str(obj.InputParameters.vectorUString),                      'Position',[70  30 100 20],'style','edit','backgroundcolor','white','Callback',@(src,evt)obj.get_u_interval);
			inp.update                         = uicontrol('Parent',hp,'String','Update',                'Position',[0   0 60 30],'Callback',@(src,evt)obj.calculate_ui);
			inp.reset                          = uicontrol('Parent',hp,'String','Reset',                 'Position',[70  0 60 30]); % TODO
			%% initialize s/c menu
			colPanelBg = [.95 1 1];
			hsc = uipanel('Title','Spacecraft','FontSize',12,'BackgroundColor',colPanelBg,'Position',[.7 .39 .3 .35]);
			popuptxt = obj.popup_list(obj.SpacecraftList);
			uiPar = {'Parent',hsc,'backgroundcolor',colPanelBg,'style','text'};
			inp.flag_sc                            = uicontrol(uiPar{:},'String','Model spacecraft','Value',0,      'Position',[0   205 120 25],'style','radio');
			inp.sc.name.text                       = uicontrol(uiPar{:},'String','spacecraft',                      'Position',[0   180 60  20]);
			inp.sc.name.value                      = uicontrol(uiPar{:},'String',popuptxt,                          'Position',[60  180 150 20],'style','popup','Callback',@(src,evt)obj.set_sc_model(src,evt));
			inp.sc.surface.text                    = uicontrol(uiPar{:},'String','surface',                         'Position',[0   160 60  20]);
			inp.sc.surface.value                   = uicontrol(uiPar{:},'String',[{'user defined'} lp.photocurrent],'Position',[60  160 150 20],'style','popup');
			inp.sc.areaTotal.text                  = uicontrol(uiPar{:},'String','Total area [m2]',                 'Position',[0   140 120 20]);
			inp.sc.areaTotal.value                 = uicontrol(uiPar{:},'String',num2str(0),'style','edit',         'Position',[120 140 50  20]);
			inp.sc.areaSunlit.text                 = uicontrol(uiPar{:},'String','Sunlit area [m2]',                'Position',[0   120 120 20],'Callback',@(src,evt)obj.get_sc_area_sunlit);
			inp.sc.areaSunlit.value                = uicontrol(uiPar{:},'String',num2str(0),'style','edit',         'Position',[120 120 50  20],'backgroundcolor','white');
			inp.sc.areaSunlitGuard.text            = uicontrol(uiPar{:},'String','Sunlit guard area [m2]',          'Position',[0   100 120  20],'Tooltipstring','Cross section area of pucks and guards, assuming similar photoelectron emission as antenna');
			inp.sc.areaSunlitGuard.value           = uicontrol(uiPar{:},'String','0','style','edit',                'Position',[120 100  50  20],'backgroundcolor','white');
			inp.sc.probeRefPotVsSatPot.text        = uicontrol(uiPar{:},'String','Probe refpot/scpot',              'Position',[0   80 120  20],'Tooltipstring','The ratio between the probe reference potential and satellite potential');
			inp.sc.probeRefPotVsSatPot.value       = uicontrol(uiPar{:},'String',num2str(0),                        'Position',[120 80  50  20],'style','edit','backgroundcolor','white');
			inp.sc.nProbes.text                    = uicontrol(uiPar{:},'String','Number of probes',                'Position',[0   60 120  20]);
			inp.sc.nProbes.value                   = uicontrol(uiPar{:},'String',num2str(0),                        'Position',[120 60  50  20],'style','edit','backgroundcolor','white');
			inp.sc.probeDistanceToSpacecraft.text  = uicontrol(uiPar{:},'String','distance probe-sc [m]',           'Position',[0   40 120  20]);
			inp.sc.probeDistanceToSpacecraft.value = uicontrol(uiPar{:},'String',num2str(0),                        'Position',[120 40  50  20],'style','edit','backgroundcolor','white');
			%% initialize plasma menu
			colPanelBg = [1 1 .95];
			hpl= uipanel('Title','Plasma','FontSize',12,'BackgroundColor',colPanelBg,'Position',[.7 .74 .3 .2]);
			popuptxt = obj.popup_list(obj.PlasmaList);
			inp.plasma.typeText = uicontrol('Parent',hpl,'String','model','style','text',  'Position',[0   100 60   20],'backgroundcolor',colPanelBg);
			inp.plasma.typeValue= uicontrol('Parent',hpl,'String',popuptxt,'style','popup','Position',[60  100 130  20],'backgroundcolor','white','Callback',@(src,evt)obj.set_plasma_model(src,evt));
			inp.plasma.nString  = uicontrol('Parent',hpl,'String','Ne [cc]',              'Position',[0 0 80 20]);
			inp.plasma.nValue   = uicontrol('Parent',hpl,'String','','style','edit',     'Position',[80 0 90 20],'backgroundcolor','white','Callback',@(src,evt)obj.get_plasma_n);
			inp.plasma.TString  = uicontrol('Parent',hpl,'String','T [eV]',          'Position',[0 20 80 20]);
			inp.plasma.TValue   = uicontrol('Parent',hpl,'String','','style','edit','Position',[80 20 90 20],'backgroundcolor','white','Callback',@(src,evt)obj.get_plasma_t);
			inp.plasma.mpString = uicontrol('Parent',hpl,'String','m [mp],0=me',     'Position',[0 40 80 20]);
			inp.plasma.mpValue  = uicontrol('Parent',hpl,'String','','style','edit','Position',[80 40 90 20],'backgroundcolor','white','Callback',@(src,evt)obj.get_plasma_mp);
			inp.plasma.qeString = uicontrol('Parent',hpl,'String','q [e]',           'Position',[0 60 80 20]);
			inp.plasma.qeValue  = uicontrol('Parent',hpl,'String','','style','edit','Position',[80 60 90 20],'backgroundcolor','white','Callback',@(src,evt)obj.get_plasma_qe);
			inp.plasma.vString  = uicontrol('Parent',hpl,'String','Vsc [km/s]',       'Position',[0 80 80 20]);
			inp.plasma.vValue   = uicontrol('Parent',hpl,'String','','style','edit','Position',[80 80 90 20],'backgroundcolor','white','Callback',@(src,evt)obj.get_plasma_v);
			%% initialize plot menu
			hpl               = uipanel('Title','Top panel','FontSize',12,'BackgroundColor',[1 1 .95],'Position',[.7 .94 .3 .06]);
			inp.toppanel.plot = uicontrol('Parent',hpl,'String','Resistance|Satellite IU|Antenna noise',...
				                  'Position',[0 0 150 25],'style','popup','backgroundcolor','white');%TODO			
			ud.inp            = inp;
			obj.figHandle     = figH;
			obj.UserData      = ud;
			
		end
		function set_plasma_model(obj,varargin)
			if nargin == 2 && any(strcmpi('user defined',varargin{1})),  %set_plasma_model(obj,'user defined')
				obj.plasmaUsed = 1;
				set(obj.UserData.inp.plasma.typeValue,'Value',1);
				return;
			elseif nargin == 2 && isnumeric(varargin{1}), %set_plasma_model(obj,numberInPlasmaList)
				idPlasma = varargin{1};
			elseif nargin == 3, %set_plasma_type(obj,hEvent,event)
				hEvent = varargin{1};
				event = varargin{2};
				disp(event);
				idPlasma = get(hEvent,'Value');
			else
				error('lp.ui.set_plasma_model unknown input');
			end
			set(obj.UserData.inp.plasma.typeValue,'Value',idPlasma);
			obj.plasmaUsed = idPlasma;
			plasma = obj.PlasmaList(idPlasma);
			set(obj.UserData.inp.plasma.nValue,'String',obj.field_to_vector_string(plasma,'n',1e-6));
			set(obj.UserData.inp.plasma.mpValue,'String',obj.field_to_vector_string(plasma,'mp'));
			set(obj.UserData.inp.plasma.TValue,'String',obj.field_to_vector_string(plasma,'T'));
			set(obj.UserData.inp.plasma.qeValue,'String',obj.field_to_vector_string(plasma,'qe'));
			set(obj.UserData.inp.plasma.vValue,'String',obj.field_to_vector_string(plasma,'v',1e-3));
		end
		function get_plasma_qe(obj)
			qeStr = get(obj.UserData.inp.plasma.qeValue,'String'); % in [e]
			if isempty(qeStr), qeStr = '-1'; end
			qe = eval(['[' qeStr ']']);
			obj.set_user_defined_if_plasma_changes('qe',qe)
		end
		function get_plasma_mp(obj)
			mpStr = get(obj.UserData.inp.plasma.mpValue,'String'); % in [e]
			if isempty(mpStr), mpStr = '-1'; end
			mp = eval(['[' mpStr ']']);
			obj.set_user_defined_if_plasma_changes('mp',mp)
		end
		function get_plasma_n(obj)
			nStr = get(obj.UserData.inp.plasma.nValue,'String'); % in [e]
			if isempty(nStr), nStr = '-1'; end
			n = eval(['[' nStr ']'])*1e6;
			obj.set_user_defined_if_plasma_changes('n',n)
		end
		function get_plasma_t(obj)
			tStr = get(obj.UserData.inp.plasma.TValue,'String'); % in [e]
			if isempty(tStr), tStr = '-1'; end
			T = eval(['[' tStr ']']);
			obj.set_user_defined_if_plasma_changes('T',T)
		end
		function get_plasma_v(obj)
			vStr = get(obj.UserData.inp.plasma.vValue,'String'); % in [e]
			if isempty(vStr), vStr = '-1'; end
			v = eval(['[' vStr ']'])*1e3; % [km/s] > [m/s]
			obj.set_user_defined_if_plasma_changes('v',v)
		end
		function set_probe_type(obj,varargin)
			if nargin == 2 && any(strcmpi('user defined',varargin{1})),  %set_probe_type(obj,'user defined')
				obj.probeUsed = 1;
				set(obj.UserData.inp.probe.type.value,'Value',1);
				obj.update_probe_area_total_vs_sunlit;
				return;
			elseif nargin == 2 && isnumeric(varargin{1}), %set_probe_type(obj,numberOfProbe)
				idProbe = varargin{1};
			elseif nargin == 3, %set_probe_type(obj,hEvent,event)
				hEvent = varargin{1};
				idProbe = get(hEvent,'Value');
			end
			obj.probeUsed = idProbe;
			probeParameters = obj.ProbeList(idProbe);
			indSurface = find(strcmp(probeParameters.surface,obj.ProbeSurfaceList));
			if indSurface,
				set(obj.UserData.inp.probe.surface.value,'Value',indSurface);
			else
				irf.log('critical',[surface '''' probeParameters.surface ''' is unknown by lp.photocurrent.']);
			end
			obj.set_probe_radius_sphere(obj.ProbeList(idProbe).radiusSphere);
			obj.set_probe_radius_wire(  obj.ProbeList(idProbe).radiusWire);
			obj.set_probe_length_wire(  obj.ProbeList(idProbe).lengthWire);
			set(obj.UserData.inp.probe.type.value,'Value',idProbe);
		end
		function set_probe_surface(obj,varargin)
			if nargin == 2 && any(strcmpi('user defined',varargin{1})),  %set_probe_type(obj,'user defined')
				obj.ProbeList(1) = obj.ProbeList(obj.probeUsed);
				obj.probeSurfaceUsed = 1;
				obj.set_probe_type(1);
				return;
			elseif nargin == 2 && isnumeric(varargin{1}), %set_probe_type(obj,numberOfSurface)
				obj.probeSurfaceUsed = varargin{1};
			elseif nargin == 3, %set_probe_type(obj,hEvent,event)
				hEvent = varargin{1};
				idProbeSurface = get(hEvent,'Value');
				if ~any(strcmp( obj.ProbeList(obj.probeUsed).surface,obj.ProbeSurfaceList(idProbeSurface) ))
					obj.ProbeList(1) = obj.ProbeList(obj.probeUsed);
					obj.probeSurfaceUsed = idProbeSurface;
					obj.ProbeList(1).surface = obj.ProbeSurfaceList{idProbeSurface};
					obj.set_probe_type('user defined');
				end
			end
		end
		function set_probe_radius_sphere(obj,radiusSphere)
			set(obj.UserData.inp.probe.radiusSphere.value,...
				'String',num2str( radiusSphere/obj.UserData.inp.probe.radiusSphere.SIconversion,2 ));
			obj.update_probe_area_total_vs_sunlit;
		end
		function get_probe_radius_sphere(obj)
			radiusSphereCm = get(obj.UserData.inp.probe.radiusSphereValue,'String'); % in cm
			if isempty(radiusSphereCm), radiusSphereCm = 0; end
			radiusSphere = str2double(radiusSphereCm)*1e-2;
			obj.set_user_defined_if_probe_changes('radiusSphere',radiusSphere)
		end
		function get_probe_radius_wire(obj)
			radiusWireCm = get(obj.UserData.inp.probe.radiusWireValue,'String'); % in cm
			if isempty(radiusWireCm), radiusWireCm = 0; end
			radiusWire = str2double(radiusWireCm)*1e-2;
			obj.set_user_defined_if_probe_changes('radiusWire',radiusWire)
		end
		function get_probe_length_wire(obj)
			lengthWireCm = get(obj.UserData.inp.probe.lengthWireValue,'String'); % in cm
			if isempty(lengthWireCm), lengthWireCm = 0; end
			lengthWire = str2double(lengthWireCm)*1e-2;
			obj.set_user_defined_if_probe_changes('lengthWire',lengthWire)
		end
		function set_sc_model(obj,varargin)
			if nargin == 2 && any(strcmpi('user defined',varargin{1})),  %set_plasma_model(obj,'user defined')
				obj.spacecraftUsed = 1;
				set(obj.UserData.inp.spacecraft.typeValue,'Value',1);
				return;
			elseif nargin == 2 && isnumeric(varargin{1}), %set_plasma_model(obj,numberInPlasmaList)
				idSpacecraft = varargin{1};
			elseif nargin == 3, %set_plasma_type(obj,hEvent,event)
				hEvent = varargin{1};
				event = varargin{2};
				disp(event);
				idSpacecraft = get(hEvent,'Value');
			else
				error('lp.ui.set_sc_model unknown input');
			end
			set(obj.UserData.inp.sc.name.value,'Value',idSpacecraft);
			obj.spacecraftUsed = idSpacecraft;
			spacecraft = obj.SpacecraftList(idSpacecraft);
			fieldsToUpdate = {'areaTotal','areaSunlit','areaSunlitGuard','probeRefPotVsSatPot','nProbes','probeDistanceToSpacecraft'};
			obj.UserData.inp.sc = obj.update_input_fields(obj.UserData.inp.sc,fieldsToUpdate,spacecraft);
		end
		function get_sc_area_sunlit(obj)
			areaSunlitStr = get(obj.UserData.inp.sc.areaSunlitValue,'String'); % in m^2
			if isempty(areaSunlitStr), areaSunlitStr = '0'; end
			areaSunlit = str2double(areaSunlitStr)*1e-2;
			obj.set_user_defined_if_sc_changes('areaSunlit',areaSunlit)
		end
		function get_factor_uv(obj)
			factorUvString = get(obj.UserData.inp.factorUvValue,'String'); % in cm
			if isempty(factorUvString), 
				factorUvString = '1';
				set(obj.UserData.inp.factorUvValue,'String','1')
			end
			obj.InputParameters.factorUV = str2double(factorUvString);
		end
		function get_distance_to_sun_au(obj)
			rSunString = get(obj.UserData.inp.rSunValue,'String'); % in cm
			if isempty(rSunString), 
				rSunString = '1';
				set(obj.UserData.inp.rSunValue,'String','1')
			end
			obj.InputParameters.rSunAU = str2double(rSunString);
		end
		function get_u_interval(obj)
			vectorUString = get(obj.UserData.inp.vectorUValue,'String'); % in cm
			if isempty(vectorUString), 
				vectorUString = '-5:10';
				set(obj.UserData.inp.vectorUValue,'String',vectorUString)
			end
			obj.InputParameters.vectorUString = vectorUString;
			obj.InputParameters.vectorU = eval(vectorUString);
		end
		function set_probe_radius_wire(obj,radiusWire)
			set(obj.UserData.inp.probe.radiusWire.value,...
				'String',num2str(radiusWire/obj.UserData.inp.probe.radiusWire.SIconversion,2));
			obj.update_probe_area_total_vs_sunlit;
		end
		function set_probe_length_wire(obj,lengthWire)
			set(obj.UserData.inp.probe.lengthWire.value,...
				'String',num2str(lengthWire/obj.UserData.inp.probe.lengthWire.SIconversion,3));
			obj.update_probe_area_total_vs_sunlit;
		end
		function get_probe_bias(obj) % input in [A]
			biasCurrenMicroA = get(obj.UserData.inp.probe.biasCurrentValue,'String'); % in [uA]
			obj.InputParameters.biasCurrent = str2double(biasCurrenMicroA) / 1e6;
		end
		function update_probe_area_total_vs_sunlit(obj)
			set(obj.UserData.inp.probe.areaTotalVsSunlit.value,...
				'String',num2str(obj.ProbeList(obj.probeUsed).Area.totalVsSunlit,3));
		end	
		function calculate_ui(obj)
			obj.get_probe_current;
			obj.plot_UI_probe;
		end
		function get_probe_current(obj)
			jProbe = lp.current(obj.ProbeList(obj.probeUsed),...
				obj.InputParameters.vectorU,...
				obj.InputParameters.rSunAU,...
				obj.InputParameters.factorUV,...
				obj.PlasmaList(obj.plasmaUsed));
			obj.Output.J = jProbe;
			obj.Output.dUdI=gradient(obj.InputParameters.vectorU,obj.Output.J.probe);
		end
		function plot_UI_probe(obj)
			% plot IU curve
			%info_txt='';
			h=obj.Axes.bottom;
			vecU = obj.InputParameters.vectorU;
			J = obj.Output.J;
			biasCurrentA = obj.InputParameters.biasCurrent;
			biasCurrentMicroA = 1e6*biasCurrentA;
			%flag_add_bias_point_values=0; % default
			plot(h,vecU, J.probe*1e6,'k');
			set(h,'xlim',[min(vecU) max(vecU)]);
			grid(h,'on');
			xlabel(h,'U [V]');
			ylabel(h,'I [\mu A]');
			
			% Add photoelectron current
			hold(h,'on');
			plot(h,vecU,J.photo*1e6,'r','linewidth',0.5);
			irf_legend(h,'    total',      [0.98 0.03],'color','k');
			irf_legend(h,' photoelectrons',[0.98 0.08],'color','r');
			clr=[0.5 0 0; 0 0.5 0; 0 0 0.5];
			for ii=1:length(J.plasma),
				plot(h,vecU,J.plasma{ii}*1e6,'linewidth',.5,'color',clr(:,ii));
				irf_legend(h,['plasma ' num2str(ii)],[0.98 0.08+ii*0.05],'color',clr(:,ii));
			end
			if biasCurrentMicroA ~= 0 && biasCurrentA>min(J.probe) && -biasCurrentA<max(J.probe), % draw bias current line
				plot(h,[vecU(1) vecU(end)],biasCurrentMicroA.*[-1 -1],'k-.','linewidth',0.5);
				text(vecU(1),-biasCurrentMicroA,'-bias','parent',h,'horizontalalignment','left','verticalalignment','bottom');
			end
			hold(h,'off');
			
		end
		function set_user_defined_if_plasma_changes(obj,idString,vector)
			if (obj.plasmaUsed ~= 1) ...
					&& numel(vector) == numel(obj.PlasmaList(obj.plasmaUsed).(idString)) ...
					&& all(vector == obj.PlasmaList(obj.plasmaUsed).(idString))
				return
			else
				obj.PlasmaList(1) = obj.PlasmaList(obj.plasmaUsed);
				obj.set_plasma_model('user defined');
			end
			obj.PlasmaList(obj.plasmaUsed).(idString) = vector;
		end
		function set_user_defined_if_probe_changes(obj,idString,vector)
			if (obj.probeUsed ~= 1) ...
					&& numel(vector) == numel(obj.ProbeList(obj.probeUsed).(idString)) ...
					&& all(vector == obj.ProbeList(obj.probeUsed).(idString))
				return
			else
				obj.ProbeList(1) = obj.ProbeList(obj.probeUsed);
				obj.set_probe_type('user defined');
			end
			obj.ProbeList(obj.probeUsed).(idString) = vector;
			obj.update_probe_area_total_vs_sunlit;
		end
		function set_user_defined_if_sc_changes(obj,idString,vector)
			if (obj.spacecraftUsed ~= 1) ...
					&& numel(vector) == numel(obj.SpacecraftList(obj.spacecraftUsed).(idString)) ...
					&& all(vector == obj.SpacecraftList(obj.spacecraftUsed).(idString))
				return
			else
				obj.SpacecraftList(1) = obj.SpacecraftList(obj.spacecraftUsed);
				obj.set_sc_model('user defined');
			end
			obj.SpacecratList(obj.spacecraftUsed).(idString) = vector;
			obj.update_sc_area_total_vs_sunlit;
		end
	end
	methods (Static)
		function popupText = popup_list(inp)
			if iscell(inp) && (numel(inp) > 0)
				popupText =inp{1};
				for ii=2:numel(inp),
					popupText(end+1:end+1+numel(inp{ii}))=['|' inp{ii}];
				end
			elseif numel(inp) > 0 && all(isprop(inp,'name'))
				popupText ='';
				for ii=1:numel(inp),
					probeName = inp(ii).name;
					if ~isempty(probeName)
						popupText(end+1:end+1+numel(probeName))=[probeName '|'];
					end
				end
				popupText(end) =[];
			end
		end
		function str = field_to_vector_string(o,field,multFactor)
			str = '';
			if nargin == 2,
				multFactor = 1;
			end
			for ii = 1:numel(o),
				str = [str num2str(o(ii).(field)*multFactor) ' ']; %#ok<AGROW>
			end
			str(end) = [];
		end
		function OutputGui = update_input_fields(InputGui,fieldsToUpdate,InputObject)
			for iField = 1:numel(fieldsToUpdate),
				field = fieldsToUpdate{iField};
				if isfield(InputGui.(field),'SIconversion')
					SIconversion = InputGui.(field).('SIconversion');
				else
					SIconversion = 1;
				end
				set(InputGui.(field).value,'String',lp.ui.field_to_vector_string(InputObject,field,SIconversion));
			end
			OutputGui = InputGui;
		end
	end
end

