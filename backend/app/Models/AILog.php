<?php
namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class AILog extends Model
{
    protected $table = 'ai_logs';
    public $timestamps = false;

    protected $casts = [
        'prompt' => 'array',
        'response' => 'array',
    ];
}
