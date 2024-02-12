const Config = new Object();
Config.closeKeys = [113, 27];

const vue = new Vue({
	el: '#main',
	data: {
		hasViewer: false,
		disabled: false,
		hasJoinedTeam: false,
		currentTeam: [],
		countDownTimer: 'รอผู้เล่นท่านอื่น',
		score: 0,
		gameTimer: 0,
		gameState: false,
		maxP: 5,
	},
	methods: {
		joinTeam() {
            this.disabled = true;
            $.post('http://dri_dungeon/joinTeam', JSON.stringify({}), (cb) => {
				if (cb.ok) {
					swal({
						text: cb.swal,
						icon: "error",
					});
					this.disabled = false;
				} else {
					this.disabled = false;
				}
            },'json');
        },
		leaveTeam() {
			$.post('http://dri_dungeon/leaveTeam', JSON.stringify({}), (cb) => {
				if (cb.ok) {
					swal({
						text: cb.swal,
						icon: "success",
					});
					this.hasJoinedTeam = false;
					this.disabled = false;
				}
			},'json');
		}
	}
});

window.addEventListener('message', (event) => {
	var event = event.data;

	if (event.message == 'openRegisterUI') {
		vue.maxP = event.max;
		$(".ui").addClass('open');
		$(".container").css('animation', 'slideUp .3s');
	} else if (event.message == 'closeUI') {
		$(".container").css('animation', 'slideDown .3s forwards');
		$(".ui").removeClass('open');
		$('.dropdown-menu').removeClass('show');
		
		if ($(".swal-overlay--show-modal").length > 0) {
			swal.close();			
		}
	} else if (event.message == 'updatePlayer') {
		vue.currentTeam = event.team;
	} else if (event.message == 'UpjoinParty') {
		vue.hasJoinedTeam = true;
	} else if (event.message == 'updateCountDownTimer') {
		vue.countDownTimer = event.timer;
	} else if (event.message == 'updateGameTimer') {
		vue.gameTimer = event.timer;
		vue.score = event.score;
		vue.currentTeam = event.team;
	} else if (event.message == 'gameEnd') {
		vue.gameState = false;
		vue.hasJoinedTeam = false;
		vue.currentTeam = [];
		vue.countDownTimer = 'รอผู้เล่นท่านอื่น';
		vue.score = 0;
		vue.gameTimer = 0;
	} else if (event.message == 'gameStart') {
		vue.gameState = true;
		$.post('http://dri_dungeon/closeUI', JSON.stringify({}));
	}
});

$("body").on("keyup", function (key) {
	if (Config.closeKeys.includes(key.which)) {
		if (!vue.hasJoinedTeam) {
			$.post('http://dri_dungeon/closeUI', JSON.stringify({}));
		}
	}
});