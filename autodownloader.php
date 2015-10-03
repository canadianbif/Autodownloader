<?php
    fclose(STDOUT);
    fclose(STDERR);
    $STDOUT = fopen('logs/phpapplication.log', 'ab');
    $STDERR = fopen('logs/phperror.log', 'ab');

    $config_file = file("config.txt");
    $raw_api_key = rtrim($config_file[0], "\n");
    $notification_email = $config_file[1];

    date_default_timezone_set('America/New_York');
    $date = "\n" . date("m/d/Y h:i:s a");
    file_put_contents("logs/phpapplication.log", $date . "\nAUTODOWNLOADER PROCESS STARTED\n\n", FILE_APPEND);

    function getUrl($url, $method='', $vars='') {
        $ch = curl_init();
        if ($method == 'post') {
            curl_setopt($ch, CURLOPT_POST, 1);
            curl_setopt($ch, CURLOPT_POSTFIELDS, $vars);
        }
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($ch, CURLOPT_FOLLOWLOCATION, 1);
        curl_setopt($ch, CURLOPT_URL, $url);
        $buffer = curl_exec($ch);
        curl_close($ch);
        return $buffer;
    }

    $api_key = array(
        'api_key' => $raw_api_key
    );

    while (true) {
        $raw_file_list = getUrl("http://api.furk.net/api/file/get", 'post', $api_key);
        $file_list = json_decode($raw_file_list, true);

        if (is_array($file_list["files"]) || is_object($file_list["files"])) {
            foreach ($file_list["files"] as $video_file) {
                if (!in_array("9749447826108549012", $video_file["id_labels"])
                                && ($video_file["id_feeds"] != "0")) {

                    $date = date("m/d/Y\nh:i:s a");
                    file_put_contents("logs/bashapplication.log", $date . ": \nDownloading " . $video_file["name"] . " ....\n", FILE_APPEND);
                    $command = './downloader.sh ' . $video_file["url_dl"] . '.zip ' . $notification_email . ' 1>>logs/bashapplication.log 2>>logs/basherror.log';
                    $exit = shell_exec($command);

                    $file_label_id = array(
                        'id_files' => $video_file["id"],
                        'id_labels' => "9749447826108549012"
                    );
                    getUrl('http://api.furk.net/api/label/link', 'post', array_merge($api_key, $file_label_id));

                }
            }
        }
        sleep(120);
    }
?>
